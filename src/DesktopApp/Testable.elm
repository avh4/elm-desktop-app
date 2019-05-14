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
    )

import DesktopApp.Ports as Ports
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


type Effect
    = WriteOut ( String, String )
    | LoadFile String


type Model yourModel
    = Model
        { appModel : yourModel
        , lastSaved : Dict String String
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
                newFiles =
                    [ config.files ]
                        |> List.map (\f -> encodeFile f model.appModel)

                isDirty ( filename, newContent ) =
                    Dict.get filename model.lastSaved /= Just newContent

                dirtyFiles =
                    newFiles
                        |> List.filter isDirty
            in
            ( Model
                { model
                    | lastSaved =
                        -- TODO: this could be optimized by using a single fold to both compute the list of effect and this new dict in a single pass
                        Dict.union (Dict.fromList dirtyFiles) model.lastSaved
                }
            , ( cmd
              , dirtyFiles
                    |> List.map WriteOut
              )
            )

        decoders =
            [ config.files ]
                |> List.map (\(File filename (JsonMapping _ decode)) -> ( filename, decode ))
                |> Dict.fromList
    in
    { init =
        \() ->
            let
                ( model, cmd ) =
                    config.init
            in
            ( Model
                { appModel = model
                , lastSaved = Dict.empty
                }
            , ( cmd
              , [ config.files ]
                    |> List.map (\(File name _) -> name)
                    |> List.map LoadFile
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
            handleLoad ( filename, result ) =
                case result of
                    Nothing ->
                        config.noOp

                    Just body ->
                        case Dict.get filename decoders of
                            Nothing ->
                                -- Log error?
                                config.noOp

                            Just decoder ->
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
                , Ports.fileLoaded handleLoad
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
    = File String (JsonMapping msg model)


encodeFile : File model msg -> model -> ( String, String )
encodeFile (File filename (JsonMapping fields _)) model =
    let
        json =
            Json.object
                (List.map (\( k, f ) -> ( k, f model )) fields)
    in
    ( filename, Json.encode 0 json )


jsonFile : String -> (b -> msg) -> JsonMapping b a -> File a msg
jsonFile filename toMsg (JsonMapping encode decode) =
    File filename (JsonMapping encode (Json.Decode.map toMsg decode))


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


staticString : String -> String -> JsonMapping a x -> JsonMapping a x
staticString name value (JsonMapping fields decoder) =
    JsonMapping (( name, \_ -> Json.string value ) :: fields) decoder
