module Page.Home exposing (Model, Msg, init, subscriptions, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Table exposing (table, tbody, td, th, thead, tr)
import Common exposing (commify, viewHttpErrorMessage)
import Config exposing (apiServer)
import Debug
import File.Download as Download
import Html exposing (Html, a, b, br, div, h1, text)
import Html.Attributes exposing (class, for, href, target, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode exposing (Decoder, field, float, int, nullable, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Regex
import RemoteData exposing (RemoteData, WebData)
import Route
import Task
import Url.Builder


type alias Model =
    { summary : WebData Summary
    , conditionFilter : Maybe String
    , conditions : WebData (List Condition)
    , searchResults : WebData (List Study)
    , sponsors : WebData (List Sponsor)
    , sponsorFilter : Maybe String
    , queryText : Maybe String
    , querySelectedConditions : List Condition
    , querySelectedSponsors : List Sponsor
    , queryDetailedDescription : Maybe String
    }


type alias Condition =
    { conditionId : Int
    , condition : String
    , numStudies : Int
    }


type alias Sponsor =
    { sponsorId : Int
    , sponsorName : String
    , numStudies : Int
    }


type alias Summary =
    { numStudies : Int
    }


type alias Study =
    { nctId : String
    , title : String
    , detailedDescription : String
    }


type Msg
    = AddCondition String
    | AddSponsor String
    | ConditionsResponse (WebData (List Condition))
    | DoSearch
    | Download
    | RemoveCondition Condition
    | RemoveSponsor Sponsor
    | Reset
    | SummaryResponse (WebData Summary)
    | SetConditionFilter String
    | SetSponsorFilter String
    | SetQueryDetailedDescription String
    | SetQueryText String
    | SearchResponse (WebData (List Study))
    | SponsorsResponse (WebData (List Sponsor))


initialModel =
    { summary = RemoteData.NotAsked
    , conditionFilter = Nothing
    , conditions = RemoteData.NotAsked
    , searchResults = RemoteData.NotAsked
    , sponsors = RemoteData.NotAsked
    , sponsorFilter = Nothing
    , queryText = Nothing
    , querySelectedConditions = []
    , querySelectedSponsors = []
    , queryDetailedDescription = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.batch [ getSummary, getConditions, getSponsors ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddCondition conditionId ->
            let
                possibleConditions =
                    case String.toInt conditionId of
                        Just newId ->
                            case model.conditions of
                                RemoteData.Success data ->
                                    Just <|
                                        List.filter
                                            (\c -> c.conditionId == newId)
                                            data

                                _ ->
                                    Nothing

                        _ ->
                            Nothing

                newConditions =
                    case possibleConditions of
                        Just someConditions ->
                            model.querySelectedConditions ++ someConditions

                        _ ->
                            model.querySelectedConditions

                newModel =
                    { model | querySelectedConditions = newConditions }
            in
            ( newModel, doSearch newModel )

        AddSponsor sponsorId ->
            let
                possibleSponsors =
                    case String.toInt sponsorId of
                        Just newId ->
                            case model.sponsors of
                                RemoteData.Success data ->
                                    Just <|
                                        List.filter
                                            (\c -> c.sponsorId == newId)
                                            data

                                _ ->
                                    Nothing

                        _ ->
                            Nothing

                newSponsors =
                    case possibleSponsors of
                        Just someSponsors ->
                            model.querySelectedSponsors ++ someSponsors

                        _ ->
                            model.querySelectedSponsors

                newModel =
                    { model | querySelectedSponsors = newSponsors }
            in
            ( newModel, doSearch newModel )

        ConditionsResponse data ->
            ( { model | conditions = data }
            , Cmd.none
            )

        DoSearch ->
            ( model, doSearch model )

        Download ->
            ( model, Download.url (searchUrl model True) )

        RemoveCondition condition ->
            let
                newConditions =
                    List.filter
                        (\c -> c.conditionId /= condition.conditionId)
                        model.querySelectedConditions

                newModel =
                    { model | querySelectedConditions = newConditions }
            in
            ( newModel, doSearch newModel )

        RemoveSponsor sponsor ->
            let
                newSponsors =
                    List.filter
                        (\s -> s.sponsorId /= sponsor.sponsorId)
                        model.querySelectedSponsors

                newModel =
                    { model | querySelectedSponsors = newSponsors }
            in
            ( newModel, doSearch newModel )

        Reset ->
            let
                newModel =
                    { model
                        | conditionFilter = Nothing
                        , searchResults = RemoteData.NotAsked
                        , sponsorFilter = Nothing
                        , queryText = Nothing
                        , querySelectedConditions = []
                        , querySelectedSponsors = []
                        , queryDetailedDescription = Nothing
                    }
            in
            ( newModel, Cmd.none )

        SummaryResponse data ->
            ( { model | summary = data }
            , Cmd.none
            )

        SearchResponse data ->
            ( { model | searchResults = data }
            , Cmd.none
            )

        SetConditionFilter text ->
            let
                newFilter =
                    case String.length text of
                        0 ->
                            Nothing

                        _ ->
                            Just (String.toLower text)
            in
            ( { model | conditionFilter = newFilter }
            , Cmd.none
            )

        SetSponsorFilter text ->
            let
                newFilter =
                    case String.length text of
                        0 ->
                            Nothing

                        _ ->
                            Just (String.toLower text)
            in
            ( { model | sponsorFilter = newFilter }
            , Cmd.none
            )

        SetQueryDetailedDescription desc ->
            let
                newDesc =
                    case String.length desc of
                        0 ->
                            Nothing

                        _ ->
                            Just desc
            in
            ( { model | queryDetailedDescription = newDesc }, Cmd.none )

        SetQueryText query ->
            let
                newQuery =
                    case String.length query of
                        0 ->
                            Nothing

                        _ ->
                            Just query
            in
            ( { model | queryText = newQuery }, Cmd.none )

        SponsorsResponse data ->
            ( { model | sponsors = data }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        summary =
            case model.summary of
                RemoteData.NotAsked ->
                    "Not asked"

                RemoteData.Loading ->
                    "Loading data..."

                RemoteData.Failure httpError ->
                    viewHttpErrorMessage httpError

                RemoteData.Success data ->
                    "Search " ++ commify data.numStudies ++ " studies"

        empty =
            [ Select.item [ value "" ] [ text "--Select--" ] ]

        mkSponsorSelect =
            let
                filterSponsors sponsors =
                    let
                        regex =
                            case model.sponsorFilter of
                                Just filter ->
                                    Just
                                        (Maybe.withDefault Regex.never
                                            (Regex.fromString filter)
                                        )

                                _ ->
                                    Nothing
                    in
                    case regex of
                        Just re ->
                            List.filter
                                (\s ->
                                    Regex.contains re
                                        (String.toLower s.sponsorName)
                                )
                                sponsors

                        _ ->
                            []

                mkSelect data =
                    case List.length data of
                        0 ->
                            text ""

                        _ ->
                            Select.select
                                [ Select.id "sponsor"
                                , Select.onChange AddSponsor
                                ]
                                (empty ++ List.map mkSelectItem data)

                mkSelectItem sponsor =
                    Select.item
                        [ value <|
                            String.fromInt sponsor.sponsorId
                        ]
                        [ text <|
                            sponsor.sponsorName
                                ++ " ("
                                ++ String.fromInt sponsor.numStudies
                                ++ ")"
                        ]
            in
            case model.sponsors of
                RemoteData.Success data ->
                    mkSelect (filterSponsors data)

                RemoteData.Failure httpError ->
                    text (viewHttpErrorMessage httpError)

                _ ->
                    text "Error fetching conditions"

        mkConditionSelect =
            let
                filterConditions conditions =
                    let
                        regex =
                            case model.conditionFilter of
                                Just filter ->
                                    Just
                                        (Maybe.withDefault Regex.never
                                            (Regex.fromString filter)
                                        )

                                _ ->
                                    Nothing
                    in
                    case regex of
                        Just re ->
                            List.filter
                                (\c ->
                                    Regex.contains re
                                        (String.toLower c.condition)
                                )
                                conditions

                        _ ->
                            []

                mkSelect data =
                    case List.length data of
                        0 ->
                            text ""

                        _ ->
                            Select.select
                                [ Select.id "condition"
                                , Select.onChange AddCondition
                                ]
                                (empty ++ List.map mkSelectItem data)

                mkSelectItem condition =
                    Select.item
                        [ value <|
                            String.fromInt condition.conditionId
                        ]
                        [ text <|
                            condition.condition
                                ++ " ("
                                ++ String.fromInt condition.numStudies
                                ++ ")"
                        ]
            in
            case model.conditions of
                RemoteData.Success data ->
                    mkSelect (filterConditions data)

                RemoteData.Failure httpError ->
                    text (viewHttpErrorMessage httpError)

                _ ->
                    text "Error fetching conditions"

        viewCondition condition =
            Button.button
                [ Button.outlinePrimary
                , Button.onClick (RemoveCondition condition)
                ]
                [ text (condition.condition ++ " ⦻") ]

        viewSponsor sponsor =
            Button.button
                [ Button.outlinePrimary
                , Button.onClick (RemoveSponsor sponsor)
                ]
                [ text (sponsor.sponsorName ++ " ⦻") ]

        viewSelectedConditions =
            List.map viewCondition model.querySelectedConditions

        viewSelectedSponsors =
            List.map viewSponsor model.querySelectedSponsors

        searchForm =
            Form.form [ onSubmit DoSearch ]
                [ Form.label [] [ text summary ]
                , Form.group []
                    [ Form.label [ for "text" ] [ text "Text:" ]
                    , Input.text
                        [ Input.attrs [ onInput SetQueryText ] ]
                    ]
                , Form.group []
                    [ Form.label [ for "text" ] [ text "Detailed Description:" ]
                    , Input.text
                        [ Input.attrs [ onInput SetQueryDetailedDescription ] ]
                    ]
                , Form.group []
                    ([ Form.label [ for "condition" ]
                        [ text "Condition:" ]
                     , Input.text
                        [ Input.attrs [ onInput SetConditionFilter ] ]
                     , mkConditionSelect
                     ]
                        ++ viewSelectedConditions
                    )
                , Form.group []
                    ([ Form.label [ for "sponsor" ]
                        [ text "Sponsor:" ]
                     , Input.text
                        [ Input.attrs [ onInput SetSponsorFilter ] ]
                     , mkSponsorSelect
                     ]
                        ++ viewSelectedSponsors
                    )
                , Button.button
                    [ Button.primary, Button.onClick DoSearch ]
                    [ text "Submit" ]
                , Button.button
                    [ Button.secondary, Button.onClick Reset ]
                    [ text "Clear" ]
                ]

        results =
            case model.searchResults of
                RemoteData.NotAsked ->
                    div [] [ text "" ]

                RemoteData.Loading ->
                    div [] [ text "Loading..." ]

                RemoteData.Failure httpError ->
                    div [] [ text (viewHttpErrorMessage httpError) ]

                RemoteData.Success studies ->
                    let
                        mkRow study =
                            tr []
                                [ td []
                                    [ b [] [ text study.title ]
                                    , br [] []
                                    , a
                                        [ Route.href
                                            (Route.Study study.nctId)
                                        , target "_blank"
                                        ]
                                        [ text study.nctId ]
                                    , br [] []
                                    , text
                                        (truncate
                                            study.detailedDescription
                                            80
                                        )
                                    ]
                                ]

                        numStudies =
                            List.length studies

                        title =
                            "Search Results (" ++ commify numStudies ++ ")"

                        resultsDiv =
                            let
                                body =
                                    case numStudies of
                                        0 ->
                                            []

                                        _ ->
                                            [ Button.button
                                                [ Button.outlinePrimary
                                                , Button.onClick Download
                                                ]
                                                [ text "Download" ]
                                            , table
                                                { options =
                                                    [ Bootstrap.Table.striped ]
                                                , thead = thead [] []
                                                , tbody =
                                                    tbody []
                                                        (List.map mkRow studies)
                                                }
                                            ]
                            in
                            [ h1 [] [ text title ] ] ++ body
                    in
                    div [] resultsDiv
    in
    Grid.container []
        [ Grid.row [ Row.centerMd ]
            [ Grid.col [ Col.mdAuto ] [ searchForm ]
            ]
        , Grid.row []
            [ Grid.col [] [ results ]
            ]
        ]


getSummary : Cmd Msg
getSummary =
    let
        url =
            apiServer ++ "/summary"
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> SummaryResponse)
                decoderSummary
        }


getConditions : Cmd Msg
getConditions =
    let
        url =
            apiServer ++ "/conditions"
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> ConditionsResponse)
                (Json.Decode.list decoderCondition)
        }


getSponsors : Cmd Msg
getSponsors =
    let
        url =
            apiServer ++ "/sponsors"
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> SponsorsResponse)
                (Json.Decode.list decoderSponsor)
        }


searchUrl : Model -> Bool -> String
searchUrl model downloadCsv =
    let
        builder ( label, value ) =
            case value of
                Just v ->
                    Just (Url.Builder.string label v)

                _ ->
                    Nothing

        conditions =
            case List.length model.querySelectedConditions of
                0 ->
                    Nothing

                _ ->
                    Just
                        (String.join ","
                            (List.map (\c -> String.fromInt c.conditionId)
                                model.querySelectedConditions
                            )
                        )

        sponsors =
            case List.length model.querySelectedSponsors of
                0 ->
                    Nothing

                _ ->
                    Just
                        (String.join ","
                            (List.map (\s -> String.fromInt s.sponsorId)
                                model.querySelectedSponsors
                            )
                        )

        downloadFlag =
            case downloadCsv of
                True ->
                    Just "1"

                _ ->
                    Nothing

        queryParams =
            Url.Builder.toQuery <|
                List.filterMap builder
                    [ ( "text"
                      , model.queryText
                      )
                    , ( "detailed_desc"
                      , model.queryDetailedDescription
                      )
                    , ( "conditions"
                      , conditions
                      )
                    , ( "sponsors"
                      , sponsors
                      )
                    , ( "download"
                      , downloadFlag
                      )
                    ]
    in
    apiServer ++ "/search/" ++ queryParams


doSearch : Model -> Cmd Msg
doSearch model =
    Http.get
        { url = searchUrl model False
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> SearchResponse)
                (Json.Decode.list decoderStudy)
        }


truncate : String -> Int -> String
truncate text max =
    case String.length text <= (max - 3) of
        True ->
            text

        _ ->
            String.left (max - 3) text ++ "..."


decoderCondition : Decoder Condition
decoderCondition =
    Json.Decode.succeed Condition
        |> Json.Decode.Pipeline.required "condition_id" int
        |> Json.Decode.Pipeline.required "condition" string
        |> Json.Decode.Pipeline.required "num_studies" int


decoderSummary : Decoder Summary
decoderSummary =
    Json.Decode.succeed Summary
        |> Json.Decode.Pipeline.required "num_studies" int


decoderStudy : Decoder Study
decoderStudy =
    Json.Decode.succeed Study
        |> Json.Decode.Pipeline.required "nct_id" string
        |> Json.Decode.Pipeline.required "title" string
        |> Json.Decode.Pipeline.optional "detailed_description" string ""


decoderSponsor : Decoder Sponsor
decoderSponsor =
    Json.Decode.succeed Sponsor
        |> Json.Decode.Pipeline.required "sponsor_id" int
        |> Json.Decode.Pipeline.required "sponsor" string
        |> Json.Decode.Pipeline.required "num_studies" int


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
