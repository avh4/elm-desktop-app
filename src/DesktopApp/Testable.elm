module DesktopApp.Testable exposing
    ( Effect(..)
    , Model
    , Msg(..)
    , program
    )

import Browser
import DesktopApp.JsonMapping as JsonMapping exposing (ObjectMapping)
import DesktopApp.Ports as Ports
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes exposing (style)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


type Effect
    = WriteUserData String
    | LoadUserData


type Model yourModel
    = Loading
    | Error String
    | Model
        { appModel : yourModel
        , lastSaved : Maybe String
        }


type Msg yourMsg
    = AppMsg yourMsg
    | UserDataLoaded (Maybe String)
    | NoOp


type alias Config model msg =
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Browser.Document msg
    , persistence : Maybe (ObjectMapping model msg)
    }


program :
    Config model msg
    ->
        { init : () -> ( Model model, ( Cmd (Msg msg), List Effect ) )
        , subscriptions : Model model -> Sub (Msg msg)
        , update : Msg msg -> Model model -> ( Model model, ( Cmd (Msg msg), List Effect ) )
        , view : Model model -> Browser.Document (Msg msg)
        }
program config =
    { init =
        \() ->
            ( Loading
            , ( Cmd.none
              , [ LoadUserData ]
              )
            )
    , update = update config
    , subscriptions = subscriptions config
    , view = view config
    }


subscriptions : Config model msg -> Model model -> Sub (Msg msg)
subscriptions config model =
    case model of
        Loading ->
            Ports.userDataLoaded UserDataLoaded

        Error _ ->
            Sub.none

        Model { appModel } ->
            config.subscriptions appModel |> Sub.map AppMsg


update : Config model msg -> Msg msg -> Model model -> ( Model model, ( Cmd (Msg msg), List Effect ) )
update config msg m =
    let
        ignore =
            ( m, ( Cmd.none, [] ) )
    in
    case m of
        Error _ ->
            ignore

        Loading ->
            case msg of
                NoOp ->
                    ignore

                AppMsg _ ->
                    -- We shouldn't be getting app messages yet
                    ignore

                UserDataLoaded Nothing ->
                    -- The file didn't exist, so let's persist the initial model
                    let
                        ( model, cmd ) =
                            config.init
                    in
                    { appModel = model
                    , lastSaved = Nothing
                    }
                        |> saveFiles config cmd

                UserDataLoaded (Just content) ->
                    case config.persistence of
                        Nothing ->
                            ( Error "Internal error: Please report this to https://github.com/avh4/elm-desktop-app/issues Received UserDataLoaded, but this app doesn't support persistence"
                            , ( Cmd.none, [] )
                            )

                        Just jsonMapping ->
                            case Json.Decode.decodeString (JsonMapping.decoder jsonMapping) content of
                                Err err ->
                                    ( Error ("Failed to open the file: " ++ Json.Decode.errorToString err)
                                    , ( Cmd.none, [] )
                                    )

                                Ok appMsg ->
                                    let
                                        ( startingAppModel, initCmd ) =
                                            config.init

                                        startingModel =
                                            Model
                                                { appModel = startingAppModel
                                                , lastSaved = Just content
                                                }

                                        ( finalModel, ( updateCmd, updateEffects ) ) =
                                            update config (AppMsg appMsg) startingModel
                                    in
                                    ( finalModel
                                    , ( Cmd.batch
                                            [ initCmd |> Cmd.map AppMsg
                                            , updateCmd
                                            ]
                                      , updateEffects
                                      )
                                    )

        Model model ->
            case msg of
                NoOp ->
                    ignore

                AppMsg appMsg ->
                    let
                        ( newModel, cmd ) =
                            config.update appMsg model.appModel
                    in
                    { model | appModel = newModel }
                        |> saveFiles config cmd

                UserDataLoaded _ ->
                    -- We shouldn't be receiving data anymore, so ignore it
                    -- TODO: log error?
                    ignore


saveFiles config cmd model =
    case config.persistence of
        Nothing ->
            ( Model model
            , ( cmd |> Cmd.map AppMsg
              , []
              )
            )

        Just jsonMapping ->
            -- TODO: is there a way we can check equality of the accessed fields in the ObjectMapping, and avoid encoding the data to Json.Value and then to String if we don't need to?
            let
                ( newLastSaved, writeEffects ) =
                    let
                        newContent =
                            JsonMapping.encodeString jsonMapping model.appModel
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


view : Config model msg -> Model model -> Browser.Document (Msg msg)
view config m =
    case m of
        Loading ->
            let
                appModel =
                    Tuple.first config.init

                { title, body } =
                    config.view appModel
            in
            { title = title
            , body =
                [ Html.div
                    [ style "width" "100%"
                    , style "background" "#ece3e7"
                    , style "min-height" "100vh"
                    ]
                    [ Html.div
                        [ style "opacity" "0.7"
                        , style "pointer-events" "none"
                        , style "user-select" "none"
                        , style "mix-blend-mode" "multiply"
                        ]
                        body
                        |> Html.map (always NoOp)
                    ]
                ]
            }

        Error message ->
            { title = "✖_✖"
            , body = [ Html.text message ]
            }

        Model model ->
            let
                { title, body } =
                    config.view model.appModel
            in
            { title = title
            , body = body |> List.map (Html.map AppMsg)
            }
