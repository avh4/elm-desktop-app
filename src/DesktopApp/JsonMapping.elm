module DesktopApp.JsonMapping exposing
    ( JsonMapping
    , encode, decoder
    , object, with, static, map
    , Codec, int, string, bool
    , maybe, list, custom, fromMapping, mapCodec
    , union, tag0, tag1, tag2
    )

{-|

@docs JsonMapping
@docs encode, decoder

@docs object, with, static, map
@docs Codec, int, string, bool
@docs maybe, list, custom, fromMapping, mapCodec
@docs union, tag0, tag1, tag2

-}

import Dict
import Json.Decode exposing (Decoder)
import Json.Encode as Json


{-| Represents both how to encode `b` into JSON, and decode `a` from JSON.

Notably, when `a` and `b` are the same it specifies a two-way mapping to and from JSON
(which can then be used with [`jsonFile`](#jsonFile)).

-}
type JsonMapping a b
    = JsonMapping (b -> List ( String, Json.Value )) (Decoder a)


{-| TODO: rename this to JsonMapping, and rename current JsonMapping to "ObjectMapping"
-}
type Codec a
    = Codec (a -> Json.Value) (Decoder a)


{-| Creates a trivial `JsonMapping`.
This, along with `with`, `static` make up a pipeline-style API
which can be used like this:

    import DesktopApp.JsonMapping exposing (JsonMapping, int, object, with)

    type alias MyData =
        { total : Int
        , count : Int
        }

    myJsonMapping : JsonMapping MyData MyData
    myJsonMapping =
        object MyData
            |> with "total" .total int
            |> with "count" .count int

-}
object : a -> JsonMapping a b
object a =
    JsonMapping (always []) (Json.Decode.succeed a)


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
encode mapping model =
    encodeValue mapping model
        |> Json.encode 0


encodeValue : JsonMapping a b -> b -> Json.Value
encodeValue (JsonMapping fields _) model =
    fields model
        |> List.reverse
        |> Json.object


int : Codec Int
int =
    Codec Json.int Json.Decode.int


string : Codec String
string =
    Codec Json.string Json.Decode.string


bool : Codec Bool
bool =
    Codec Json.bool Json.Decode.bool


maybe : Codec a -> Codec (Maybe a)
maybe (Codec enc dec) =
    Codec
        (Maybe.map enc >> Maybe.withDefault Json.null)
        (Json.Decode.nullable dec)


list : Codec a -> Codec (List a)
list (Codec enc dec) =
    Codec (Json.list enc) (Json.Decode.list dec)


custom : (a -> Json.Value) -> Decoder a -> Codec a
custom enc dec =
    Codec enc dec


mapCodec : (b -> a) -> (a -> b) -> Codec a -> Codec b
mapCodec en de (Codec enc dec) =
    Codec (en >> enc) (Json.Decode.map de dec)


fromMapping : JsonMapping a a -> Codec a
fromMapping mapping =
    Codec (encodeValue mapping) (decoder mapping)


{-| Adds a field to an object. It will be represented in both your Elm model and in the JSON.
-}
with : String -> (x -> a) -> Codec a -> JsonMapping (a -> b) x -> JsonMapping b x
with name get (Codec toJson fd) (JsonMapping fields dec) =
    JsonMapping
        (\x -> ( name, get x |> toJson ) :: fields x)
        (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) dec)


{-| Adds a static field to an object. The field will not be represented in your Elm model,
but this exact field name and string value will be added to the written-out JSON file.
-}
static : String -> Codec a -> a -> JsonMapping b x -> JsonMapping b x
static name (Codec enc _) value (JsonMapping fields dec) =
    JsonMapping
        (\x -> ( name, enc value ) :: fields x)
        dec



-- TODO: a function to hardcode a parameter into the Elm value which is not in the JSON
-- TODO: ? a function to hardcode a value in the JSON, but also pass it to Elm (maybe not necessary with static and a way to hardcode only into Elm?)


union : List (VariantDecoder x) -> (x -> VariantEncoder) -> JsonMapping x x
union dec enc =
    JsonMapping
        (\x ->
            case enc x of
                VariantEncoder tagName fields ->
                    List.reverse fields ++ [ ( "$", Json.string tagName ) ]
        )
        (Json.Decode.field "$" Json.Decode.string
            |> Json.Decode.andThen
                (\t ->
                    case
                        -- TODO: this is probably faster to just recurse through the list instead of transforming into a Dict
                        dec
                            |> List.map (\(VariantDecoder p) -> ( p.tag, p.decode ))
                            |> Dict.fromList
                            |> Dict.get t
                    of
                        Nothing ->
                            Json.Decode.fail <|
                                String.concat
                                    [ "Unknown tag: expected one of ["
                                    , String.join ", " (List.map (\(VariantDecoder p) -> p.tag) dec)
                                    , "], but got: "
                                    , t
                                    ]

                        Just d ->
                            d
                )
        )


type alias Variant x f =
    { decode : VariantDecoder x
    , encode : f
    }


type VariantDecoder x
    = VariantDecoder
        { tag : String
        , decode : Decoder x
        }


type VariantEncoder
    = VariantEncoder String (List ( String, Json.Value ))


tag0 : String -> x -> Variant x VariantEncoder
tag0 name f =
    { decode =
        VariantDecoder
            { tag = name
            , decode =
                Json.Decode.succeed f
            }
    , encode =
        VariantEncoder
            name
            []
    }


tag1 : String -> (a -> x) -> ( String, Codec a ) -> Variant x (a -> VariantEncoder)
tag1 name f ( an, Codec ac ad ) =
    { decode =
        VariantDecoder
            { tag = name
            , decode =
                Json.Decode.map f
                    (Json.Decode.field an ad)
            }
    , encode =
        \a ->
            VariantEncoder
                name
                [ ( an, ac a )
                ]
    }


tag2 : String -> (a -> b -> x) -> ( String, Codec a ) -> ( String, Codec b ) -> Variant x (a -> b -> VariantEncoder)
tag2 name f ( an, Codec ac ad ) ( bn, Codec bc bd ) =
    { decode =
        VariantDecoder
            { tag = name
            , decode =
                Json.Decode.map2 f
                    (Json.Decode.field an ad)
                    (Json.Decode.field bn bd)
            }
    , encode =
        \a b ->
            VariantEncoder
                name
                [ ( an, ac a )
                , ( bn, bc b )
                ]
    }
