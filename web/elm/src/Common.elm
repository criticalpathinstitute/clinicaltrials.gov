module Common exposing (commify, viewHttpErrorMessage)

import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), usLocale)
import Http


commify : Int -> String
commify =
    format { usLocale | decimals = Exact 0 } << toFloat


viewHttpErrorMessage : Http.Error -> String
viewHttpErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message
