module Connection exposing (Model, Msg(..), expectResponse, initial, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Utilities.Spacing as Spacing
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Url.Builder as B


url =
    { base = "http://localhost"
    }


type alias Model =
    { thing : String
    , token : String
    , channel : String
    , response : String
    }


initial : Model
initial =
    { thing = ""
    , token = ""
    , channel = ""
    , response = ""
    }


type Msg
    = SubmitThing String
    | SubmitToken String
    | SubmitChannel String
    | Connect
    | Disconnect
    | GotResponse (Result Http.Error Int)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SubmitChannel channel ->
            ( { model | channel = channel }, Cmd.none )

        SubmitThing thing ->
            ( { model | thing = thing }, Cmd.none )

        SubmitToken token ->
            ( { model | token = token }, Cmd.none )

        Connect ->
            ( model
            , Http.request
                { method = "PUT"
                , headers = [ Http.header "Authorization" model.token ]
                , url = B.crossOrigin url.base [ "channels", model.channel, "things", model.thing ] []
                , body = Http.emptyBody
                , expect = expectResponse GotResponse
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        Disconnect ->
            ( model
            , Http.request
                { method = "DELETE"
                , headers = [ Http.header "Authorization" model.token ]
                , url = B.crossOrigin url.base [ "channels", model.channel, "things", model.thing ] []
                , body = Http.emptyBody
                , expect = expectResponse GotResponse
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        GotResponse result ->
            case result of
                Ok statusCode ->
                    ( { model | response = "Ok " ++ String.fromInt statusCode }, Cmd.none )

                Err error ->
                    ( { model | response = Error.handle error }, Cmd.none )


view : Model -> Html Msg
view model =
    Grid.row []
        [ Grid.col []
            [ Form.form []
                [ Form.group []
                    [ Form.label [ for "chan" ] [ text "Channel" ]
                    , Input.email [ Input.id "chan", Input.onInput SubmitChannel ]
                    ]
                , Form.group []
                    [ Form.label [ for "token" ] [ text "Token" ]
                    , Input.text [ Input.id "token", Input.onInput SubmitToken ]
                    ]
                , Form.group []
                    [ Form.label [ for "thing" ] [ text "Thing" ]
                    , Input.text [ Input.id "thing", Input.onInput SubmitThing ]
                    ]
                , Button.button [ Button.primary, Button.attrs [ Spacing.ml1 ], Button.onClick Connect ] [ text "Connect" ]
                , Button.button [ Button.primary, Button.attrs [ Spacing.ml1 ], Button.onClick Disconnect ] [ text "Disonnect" ]
                ]
            , Html.hr [] []
            , text ("response: " ++ model.response)
            ]
        ]


expectResponse : (Result Http.Error Int -> Msg) -> Http.Expect Msg
expectResponse toMsg =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ u ->
                    Err (Http.BadUrl u)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata body ->
                    Err (Http.BadStatus metadata.statusCode)

                Http.GoodStatus_ metadata _ ->
                    Ok metadata.statusCode
