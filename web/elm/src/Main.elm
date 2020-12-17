module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Bootstrap.Navbar as Navbar
import Browser
import Browser.Navigation as Nav
import Config
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.Home
import Page.Study
import PageView
import Route exposing (Route)
import Url


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , curPage : Page
    , navbarState : Navbar.State
    }


type Page
    = Home Page.Home.Model
    | Study String Page.Study.Model


type Msg
    = LinkClicked Browser.UrlRequest
    | NavbarMsg Navbar.State
    | UrlChanged Url.Url
    | HomeMsg Page.Home.Msg
    | StudyMsg Page.Study.Msg


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg

        ( subModel, subMsg ) =
            Page.Home.init
    in
    ( { key = key
      , url = url
      , curPage = Home subModel
      , navbarState = navbarState
      }
    , Cmd.batch [ navbarCmd, Cmd.map HomeMsg subMsg ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.curPage ) of
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                Browser.External href ->
                    ( model, Nav.load href )

        ( UrlChanged url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( NavbarMsg state, _ ) ->
            ( { model | navbarState = state }, Cmd.none )

        ( HomeMsg subMsg, Home subModel ) ->
            let
                ( newSubModel, newCmd ) =
                    Page.Home.update subMsg subModel
            in
            ( { model | curPage = Home newSubModel }
            , Cmd.map HomeMsg newCmd
            )

        ( StudyMsg subMsg, Study nctId subModel ) ->
            let
                ( newSubModel, newCmd ) =
                    Page.Study.update subMsg subModel
            in
            ( { model | curPage = Study nctId newSubModel }
            , Cmd.map StudyMsg newCmd
            )

        ( _, _ ) ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    let
        navConfig =
            Navbar.config NavbarMsg
    in
    case model.curPage of
        Home subModel ->
            PageView.view navConfig
                model.navbarState
                (Html.map HomeMsg (Page.Home.view subModel))

        Study nctId subModel ->
            PageView.view navConfig
                model.navbarState
                (Html.map StudyMsg
                    (Page.Study.view subModel)
                )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.curPage of
        Home subModel ->
            Sub.map HomeMsg
                (Page.Home.subscriptions subModel)

        _ ->
            Sub.none


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        _ =
            Debug.log "maybeRoute" maybeRoute

        _ =
            Debug.log "model" model
    in
    case maybeRoute of
        Just (Route.Study nctId) ->
            let
                ( subModel, subMsg ) =
                    Page.Study.init nctId
            in
            ( { model | curPage = Study nctId subModel }
            , Cmd.map StudyMsg subMsg
            )

        _ ->
            let
                ( subModel, subMsg ) =
                    Page.Home.init
            in
            ( { model | curPage = Home subModel }, Cmd.map HomeMsg subMsg )
