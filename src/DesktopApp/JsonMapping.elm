module DesktopApp.JsonMapping exposing
    ( ObjectMapping
    , encode, decoder
    , object, with, static, map
    , Codec, int, string, bool
    , maybe, list, custom, fromMapping, mapCodec
    , union, tag0, tag1, tag2
    )

{-|

@docs ObjectMapping
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
type ObjectMapping encodesFrom decodesTo
    = ObjectMapping (encodesFrom -> List ( String, Json.Value )) (Decoder decodesTo)


{-| TODO: rename this to JsonMapping, and rename current JsonMapping to "ObjectMapping"
-}
type Codec a
    = Codec (a -> Json.Value) (Decoder a)


{-| Creates a trivial `ObjectMapping`.
This, along with `with`, `static` make up a pipeline-style API
which can be used like this:

    import DesktopApp.JsonMapping exposing (ObjectMapping, int, object, with)

    type alias MyData =
        { total : Int
        , count : Int
        }

    myObjectMapping : ObjectMapping MyData MyData
    myObjectMapping =
        object MyData
            |> with "total" .total int
            |> with "count" .count int

-}
object : decodesTo -> ObjectMapping encodesFrom decodesTo
object a =
    ObjectMapping (always []) (Json.Decode.succeed a)


{-| Transforms the type that a ObjectMapping decodes.
-}
map : (a -> b) -> ObjectMapping encodesFrom a -> ObjectMapping encodesFrom b
map f (ObjectMapping fields decode) =
    ObjectMapping fields (Json.Decode.map f decode)


{-| Gets the Json.Decode.Decoder for the given ObjectMapping.
-}
decoder : ObjectMapping encodesFrom decodesTo -> Decoder decodesTo
decoder (ObjectMapping _ dec) =
    dec


{-| Encodes a given value with the given ObjectMapping (into a JSON string).
-}
encode : ObjectMapping encodesFrom decodesTo -> encodesFrom -> String
encode mapping model =
    encodeValue mapping model
        |> Json.encode 0


encodeValue : ObjectMapping encodesFrom decodesTo -> encodesFrom -> Json.Value
encodeValue (ObjectMapping fields _) model =
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


fromMapping : ObjectMapping a a -> Codec a
fromMapping mapping =
    Codec (encodeValue mapping) (decoder mapping)


{-| Adds a field to an object. It will be represented in both your Elm model and in the JSON.
-}
with :
    String
    -> (encodesFrom -> a)
    -> Codec a
    -> ObjectMapping encodesFrom (a -> decodesTo)
    -> ObjectMapping encodesFrom decodesTo
with name get (Codec toJson fd) (ObjectMapping fields dec) =
    ObjectMapping
        (\x -> ( name, get x |> toJson ) :: fields x)
        (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) dec)


{-| Adds a static field to an object. The field will not be represented in your Elm model,
but this exact field name and string value will be added to the written-out JSON file.
-}
static : String -> Codec a -> a -> ObjectMapping encodesFrom decodesTo -> ObjectMapping encodesFrom decodesTo
static name (Codec enc _) value (ObjectMapping fields dec) =
    ObjectMapping
        (\x -> ( name, enc value ) :: fields x)
        dec



-- TODO: a function to hardcode a parameter into the Elm value which is not in the JSON
-- TODO: ? a function to hardcode a value in the JSON, but also pass it to Elm (maybe not necessary with static and a way to hardcode only into Elm?)


union : List (VariantDecoder a) -> (a -> VariantEncoder) -> ObjectMapping a a
union dec enc =
    ObjectMapping
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
