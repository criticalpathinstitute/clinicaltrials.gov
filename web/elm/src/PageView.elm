module PageView exposing (view)

import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import Bootstrap.Utilities.Spacing as Spacing
import Browser exposing (Document)
import Html exposing (Html, a, div, img, input, text)
import Html.Attributes exposing (class, href, placeholder, src)
import Route exposing (Route)


view : Navbar.Config msg -> Navbar.State -> Html msg -> Document msg
view navConfig navbarState content =
    let
        nav =
            navConfig
                |> Navbar.withAnimation
                |> Navbar.brand
                    [ Route.href Route.Home ]
                    [ img [ src "./assets/images/logo.png" ] [] ]
                |> Navbar.view navbarState
    in
    { title = "Clinical Trials Portal"
    , body =
        [ Grid.container []
            [ Grid.row []
                [ Grid.col
                    []
                    [ nav
                    , content
                    ]
                ]
            ]
        ]
    }
