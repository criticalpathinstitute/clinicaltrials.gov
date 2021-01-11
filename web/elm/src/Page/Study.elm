module Page.Study exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table exposing (simpleThead, table, tbody, td, th, tr)
import Common exposing (commify, viewHttpErrorMessage)
import Config exposing (apiServer, serverAddress)
import Html exposing (Html, a, div, h1, h2, text)
import Html.Attributes exposing (..)
import Http
import Json.Decode exposing (Decoder, field, float, int, nullable, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import RemoteData exposing (RemoteData, WebData)
import Route
import Url.Builder


type alias Model =
    { study : WebData Study
    }


type alias Study =
    { nctId : String
    , title : String
    , detailedDescription : String
    }


type Msg
    = StudyResponse (WebData Study)


init : String -> ( Model, Cmd Msg )
init nctId =
    ( { study = RemoteData.NotAsked
      }
    , Cmd.batch [ getStudy nctId ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StudyResponse data ->
            ( { model | study = data }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    let
        studyView =
            case model.study of
                RemoteData.NotAsked ->
                    div [] [ text "Not asked" ]

                RemoteData.Loading ->
                    div [] [ text "Loading data..." ]

                RemoteData.Failure httpError ->
                    div [] [ text (viewHttpErrorMessage httpError) ]

                RemoteData.Success study ->
                    div []
                        [ h1 [] [ text <| "Study: " ++ study.title ]
                        , text study.detailedDescription
                        ]
    in
    Grid.container []
        [ Grid.row []
            [ Grid.col [ Col.md8 ] [ studyView ]
            ]
        ]


alignRight =
    Bootstrap.Table.cellAttr (style "text-align" "right")


getStudy : String -> Cmd Msg
getStudy nctId =
    let
        url =
            apiServer ++ "/study/" ++ nctId
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> StudyResponse)
                decoderStudy
        }


decoderStudy : Decoder Study
decoderStudy =
    Json.Decode.succeed Study
        |> Json.Decode.Pipeline.required "nct_id" string
        |> Json.Decode.Pipeline.required "title" string
        |> Json.Decode.Pipeline.required "detailed_description" string


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
