module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy)
import Http
import Json.Decode as Decode exposing (Decoder, Value, decodeString, field, string)
import Json.Encode as E
import List exposing (filter, map, sortBy)
import Url
import Url.Builder exposing (absolute, relative)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, oneOf, s)
import Url.Parser.Query as Query


main : Program (Maybe String) Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , subscriptions = subscriptions
        , view = view
        , update = update
        }



-- MODEL


type alias Model =
    { route : Route
    , session : Session
    }


init : Maybe String -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model (urlToRoute url) (Guest key { navMenuOpen = False })
    , Cmd.none
    )


type Route
    = Home
    | Login
    | Logout
    | SignUp
    | GoogleOAuth (Maybe String)
    | NotFound


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map Login (s "login")
        , Parser.map Logout (s "logout")
        , Parser.map GoogleOAuth (s "oauth" </> s "google" <?> Query.string "code")
        ]


type alias Cred =
    String


type Session
    = LoggedIn Nav.Key ScreenState Cred
    | Guest Nav.Key ScreenState


type alias ScreenState =
    { navMenuOpen : Bool }


modelToNavKey : Model -> Nav.Key
modelToNavKey model =
    case model.session of
        LoggedIn key _ _ ->
            key

        Guest key _ ->
            key


sessionMenuOpen : Session -> Bool
sessionMenuOpen session =
    case session of
        LoggedIn _ state _ ->
            state.navMenuOpen

        Guest _ state ->
            state.navMenuOpen



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotUserInfo (Result Http.Error String)
    | ToggleNavMenu


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl (modelToNavKey model) (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        UrlChanged url ->
            ( { model | route = urlToRoute url }, Cmd.none )

        GotUserInfo info ->
            ( model, Cmd.none )

        ToggleNavMenu ->
            ( { model | session = toggleSessionMenuOpen model.session }, Cmd.none )


toggleSessionMenuOpen : Session -> Session
toggleSessionMenuOpen session =
    let
        toggle state =
            { state | navMenuOpen = not state.navMenuOpen }
    in
    case session of
        Guest key state ->
            Guest key (toggle state)

        LoggedIn key state viewer ->
            LoggedIn key (toggle state) viewer



-- VIEW


fa : String -> Html Msg
fa icon =
    i [ class icon ] []


urlToRoute : Url.Url -> Route
urlToRoute url =
    Maybe.withDefault NotFound (Parser.parse parser url)


href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToUrl targetRoute)


routeToUrl : Route -> String
routeToUrl route =
    case route of
        Home ->
            "/"

        SignUp ->
            "/signup"

        Login ->
            "/login"

        Logout ->
            "/logout"

        GoogleOAuth maybeCode ->
            case maybeCode of
                Just code ->
                    "/outh/google?code=" ++ Url.percentEncode code

                Nothing ->
                    "/oauth/google?error=unknowncode"

        NotFound ->
            "/404"


routeToTitle : Route -> String
routeToTitle route =
    case route of
        Home ->
            "소개"

        SignUp ->
            "가입"

        Login ->
            "로그인"

        Logout ->
            "로그아웃"

        GoogleOAuth code ->
            "인증"

        NotFound ->
            "404"


view : Model -> Browser.Document Msg
view model =
    { title = "HTML.coffee - " ++ routeToTitle model.route
    , body =
        [ div [ class "wrap" ] [ menuView model, mainView model ]
        , footerView model
        ]
    }


mainView : Model -> Html Msg
mainView model =
    let
        titlef : String -> Html Msg -> List (Html Msg)
        titlef title content =
            [ h1 [ class "title" ] [ text title ], content ]
    in
    div [ class "container" ]
        [ div [ class "columns is-centered" ]
            [ main_ [ class "column has-text-justified" ]
                (case model.route of
                    Home ->
                        homeView model

                    Login ->
                        [ loginView model ]

                    SignUp ->
                        [ text "가입" ]

                    GoogleOAuth (Just code) ->
                        [ h1 [] [ text "구글 인증" ]
                        , div [] [ text code ]
                        ]

                    _ ->
                        titlef "404 찾을 수 없습니다" notFoundView
                )
            ]
        ]


menuView : Model -> Html Msg
menuView { route, session } =
    nav [ class "navbar" ]
        [ div [ class "navbar-brand" ]
            [ a [ class "navbar-item", href Home ]
                [ text "Thankyou.coffee" ]
            , div
                [ attribute "role" "button"
                , attribute "aria-label" "menu"
                , attribute "aria-expanded" "true"
                , attribute "data-target" "coffeeNavbar"
                , onClick ToggleNavMenu
                , Attr.href "#"
                , class "navbar-burger burger"
                , classList [ ( "is-active", sessionMenuOpen session ) ]
                ]
                (List.repeat 3 (span [ attribute "aria-hidden" "true" ] []))
            ]
        , div
            [ id "coffeeNavbar"
            , class "navbar-menu"
            , classList [ ( "is-active", sessionMenuOpen session ) ]
            ]
            [ div [ class "navbar-start" ]
                [ a [ class "navbar-item", href Home ] [ text "소개" ]
                , a [ class "navbar-item", href Home ] [ text "소개" ]
                , a [ class "navbar-item", href Home ] [ text "소개" ]
                ]
            , div [ class "navbar-end" ]
                [ div [ class "navbar-item" ]
                    [ div [ class "buttons" ]
                        [ a [ class "button is-primary", href Login ]
                            [ fa "fas fa-sign-in-alt"
                            , text " 로그인"
                            ]
                        ]
                    ]
                ]
            ]
        ]


footerView : Model -> Html Msg
footerView model =
    footer [ class "footer" ]
        [ div [ class "content has-text-justified" ]
            [ p [] [ text "HTML.coffee" ]
            ]
        ]


homeView : Model -> List (Html Msg)
homeView model =
    [ ul []
        [ li [] [ a [ href Home ] [ text "소개" ] ]
        , li [] [ a [ href Login ] [ text "로그인" ] ]
        ]
    , node "code-editor" [ style "height" "500px", style "width" "100%" ] []
    ]


notFoundView : Html Msg
notFoundView =
    text "404 찾을 수 없습니다"


loginView : Model -> Html Msg
loginView model =
    section [ class "로그인" ] []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
