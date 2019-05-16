module DesktopApp.JsonMapping exposing
    ( JsonMapping
    , encode, decoder
    , object, map, withInt, withString, with, staticString
    )

{-|

@docs JsonMapping
@docs encode, decoder

@docs object, map, withInt, withString, with, staticString

-}

import Json.Decode exposing (Decoder)
import Json.Encode as Json


{-| Represents both how to encode `b` into JSON, and decode `a` from JSON.

Notably, when `a` and `b` are the same it specifies a two-way mapping to and from JSON
(which can then be used with [`jsonFile`](#jsonFile)).

-}
type JsonMapping a b
    = JsonMapping (List ( String, b -> Json.Value )) (Decoder a)


{-| Creates a trivial `JsonMapping`.
This, along with `withInt`, `staticString`, `with` make up a pipeline-style API
which can be used like this:

    import DesktopApp.JsonMapping exposing (JsonMapping, object, withInt)

    type alias MyData =
        { total : Int
        , count : Int
        }

    myJsonMapping : JsonMapping MyData MyData
    myJsonMapping =
        object MyData
            |> withInt "total" .total
            |> withInt "count" .count

-}
object : a -> JsonMapping a b
object a =
    JsonMapping [] (Json.Decode.succeed a)


{-| Transforms the type that a JsonMapping decodes.
-}
map : (a -> b) -> JsonMapping a x -> JsonMapping b x
map f (JsonMapping fields decode) =
    JsonMapping fields (Json.Decode.map f decode)


{-| Gets the Json.Decode.Decoder for the given JsonMapping.
-}
decoder : JsonMapping a b -> Decoder a
decoder (JsonMapping _ dec) =
    dec


{-| Encodes a given value with the given JsonMapping (into a JSON string).
-}
encode : JsonMapping a b -> b -> String
encode (JsonMapping fields _) model =
    let
        json =
            Json.object
                (List.map (\( k, f ) -> ( k, f model )) fields)
    in
    Json.encode 0 json


{-| Adds a field to an object. It will be represented in both your Elm model and in the JSON.
-}
with : String -> (x -> a) -> (a -> Json.Value) -> Decoder a -> JsonMapping (a -> b) x -> JsonMapping b x
with name get toJson fd (JsonMapping fields dec) =
    JsonMapping (( name, get >> toJson ) :: fields) (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) dec)


{-| Adds an integer field to an object. It will be represented in both your Elm model and in the JSON.
-}
withInt : String -> (x -> Int) -> JsonMapping (Int -> b) x -> JsonMapping b x
withInt name get =
    with name get Json.int Json.Decode.int


{-| Adds an string field to an object. It will be represented in both your Elm model and in the JSON.
-}
withString : String -> (x -> String) -> JsonMapping (String -> b) x -> JsonMapping b x
withString name get =
    with name get Json.string Json.Decode.string


{-| Adds a static string field to an object. The field will not be represented in your Elm model,
but this exact field name and string value will be added to the written-out JSON file.
-}
staticString : String -> String -> JsonMapping a x -> JsonMapping a x
staticString name value (JsonMapping fields dec) =
    JsonMapping (( name, \_ -> Json.string value ) :: fields) dec
