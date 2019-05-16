module DesktopApp.Testable exposing
    ( Effect(..)
    , Model
    , Msg(..)
    , program
    )

import Browser
import DesktopApp.JsonMapping as JsonMapping exposing (JsonMapping)
import DesktopApp.Ports as Ports
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


type Effect
    = WriteUserData String
    | LoadUserData


type Model yourModel
    = Model
        { appModel : yourModel
        , lastSaved : Maybe String
        }


type Msg yourMsg
    = AppMsg yourMsg


program :
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Browser.Document msg
    , persistence : Maybe (JsonMapping msg model)
    , noOp : msg
    }
    ->
        { init : () -> ( Model model, ( Cmd (Msg msg), List Effect ) )
        , subscriptions : Model model -> Sub (Msg msg)
        , update : Msg msg -> Model model -> ( Model model, ( Cmd (Msg msg), List Effect ) )
        , view : Model model -> Browser.Document (Msg msg)
        }
program config =
    let
        saveFiles cmd (Model model) =
            case config.persistence of
                Nothing ->
                    ( Model model
                    , ( cmd |> Cmd.map AppMsg
                      , []
                      )
                    )

                Just jsonMapping ->
                    -- TODO: is there a way we can check equality of the accessed fields in the JsonMapping, and avoid encoding the data to Json.Value and then to String if we don't need to?
                    let
                        ( newLastSaved, writeEffects ) =
                            let
                                newContent =
                                    JsonMapping.encode jsonMapping model.appModel
                            in
                            if model.lastSaved == Just newContent then
                                -- This file hasn't changed, so do nothing
                                ( model.lastSaved, [] )

                            else
                                -- This file needs to be written out
                                ( Just newContent
                                , [ WriteUserData newContent ]
                                )
                    in
                    ( Model { model | lastSaved = newLastSaved }
                    , ( cmd |> Cmd.map AppMsg
                      , writeEffects
                      )
                    )
    in
    { init =
        \() ->
            let
                ( model, cmd ) =
                    config.init
            in
            ( Model
                { appModel = model
                , lastSaved = Nothing
                }
            , ( cmd |> Cmd.map AppMsg
              , [ LoadUserData ]
              )
            )
    , update =
        \msg (Model model) ->
            case msg of
                AppMsg appMsg ->
                    let
                        ( newModel, cmd ) =
                            config.update appMsg model.appModel
                    in
                    Model { model | appModel = newModel }
                        |> saveFiles cmd
    , subscriptions =
        let
            handleLoad result =
                case ( result, config.persistence ) of
                    ( _, Nothing ) ->
                        -- We shouldn't have tried to a load a file since this app doesn't support persistence
                        -- Technically this is an error condition, but it's safe to just ignore the data
                        config.noOp

                    ( Nothing, Just _ ) ->
                        config.noOp

                    ( Just body, Just jsonMapping ) ->
                        case Json.Decode.decodeString (JsonMapping.decoder jsonMapping) body of
                            Err err ->
                                -- Log error?
                                config.noOp

                            Ok value ->
                                value
        in
        \(Model model) ->
            Sub.batch
                [ config.subscriptions model.appModel |> Sub.map AppMsg
                , Ports.userDataLoaded handleLoad |> Sub.map AppMsg
                ]
    , view =
        \(Model model) ->
            let
                { title, body } =
                    config.view model.appModel
            in
            { title = title
            , body = body |> List.map (Html.map AppMsg)
            }
    }
