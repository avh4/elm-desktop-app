module DesktopApp.Testable exposing
    ( Effect(..)
    , File
    , JsonMapping
    , Model
    , jsonFile
    , jsonMapping
    , program
    , staticString
    , with
    , withInt
    , withString
    )

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
    , view : model -> Html msg
    , files : File model msg
    , noOp : msg
    }
    ->
        { init : () -> ( Model model, ( Cmd msg, List Effect ) )
        , subscriptions : Model model -> Sub msg
        , update : msg -> Model model -> ( Model model, ( Cmd msg, List Effect ) )
        , view : Model model -> { body : List (Html msg), title : String }
        }
program config =
    let
        saveFiles cmd (Model model) =
            -- TODO: is there a way we can check equality of the accessed fields in the JsonMapping, and avoid encoding the data to Json.Value and then to String if we don't need to?
            let
                ( newLastSaved, writeEffects ) =
                    let
                        newContent =
                            encodeFile config.files model.appModel
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

        decoder =
            config.files
                |> (\(File (JsonMapping _ decode)) -> decode)
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
                        case Json.Decode.decodeString decoder body of
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
            { title = ""
            , body =
                [ config.view model.appModel
                ]
            }
    }


type File model msg
    = File (JsonMapping msg model)


encodeFile : File model msg -> model -> String
encodeFile (File (JsonMapping fields _)) model =
    let
        json =
            Json.object
                (List.map (\( k, f ) -> ( k, f model )) fields)
    in
    Json.encode 0 json


jsonFile : (b -> msg) -> JsonMapping b a -> File a msg
jsonFile toMsg (JsonMapping encode decode) =
    File (JsonMapping encode (Json.Decode.map toMsg decode))


type JsonMapping a b
    = JsonMapping (List ( String, b -> Json.Value )) (Decoder a)


jsonMapping : a -> JsonMapping a b
jsonMapping a =
    JsonMapping [] (Json.Decode.succeed a)


with : String -> (x -> a) -> (a -> Json.Value) -> Decoder a -> JsonMapping (a -> b) x -> JsonMapping b x
with name get toJson fd (JsonMapping fields decoder) =
    JsonMapping (( name, get >> toJson ) :: fields) (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) decoder)


withInt : String -> (x -> Int) -> JsonMapping (Int -> b) x -> JsonMapping b x
withInt name get =
    with name get Json.int Json.Decode.int


withString : String -> (x -> String) -> JsonMapping (String -> b) x -> JsonMapping b x
withString name get =
    with name get Json.string Json.Decode.string


staticString : String -> String -> JsonMapping a x -> JsonMapping a x
staticString name value (JsonMapping fields decoder) =
    JsonMapping (( name, \_ -> Json.string value ) :: fields) decoder
