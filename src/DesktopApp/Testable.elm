module DesktopApp.Testable exposing
    ( Effect(..)
    , Model
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


program :
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Browser.Document msg
    , persistence : JsonMapping msg model
    , noOp : msg
    }
    ->
        { init : () -> ( Model model, ( Cmd msg, List Effect ) )
        , subscriptions : Model model -> Sub msg
        , update : msg -> Model model -> ( Model model, ( Cmd msg, List Effect ) )
        , view : Model model -> Browser.Document msg
        }
program config =
    let
        saveFiles cmd (Model model) =
            -- TODO: is there a way we can check equality of the accessed fields in the JsonMapping, and avoid encoding the data to Json.Value and then to String if we don't need to?
            let
                ( newLastSaved, writeEffects ) =
                    let
                        newContent =
                            JsonMapping.encode config.persistence model.appModel
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
            , ( cmd
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
            , ( cmd
              , [ LoadUserData ]
              )
            )
    , update =
        \msg (Model model) ->
            let
                ( newModel, cmd ) =
                    config.update msg model.appModel
            in
            Model { model | appModel = newModel }
                |> saveFiles cmd
    , subscriptions =
        let
            handleLoad result =
                case result of
                    Nothing ->
                        config.noOp

                    Just body ->
                        case Json.Decode.decodeString (JsonMapping.decoder config.persistence) body of
                            Err err ->
                                -- Log error?
                                config.noOp

                            Ok value ->
                                value
        in
        \(Model model) ->
            Sub.batch
                [ config.subscriptions model.appModel
                , Ports.userDataLoaded handleLoad
                ]
    , view =
        \(Model model) ->
            config.view model.appModel
    }
