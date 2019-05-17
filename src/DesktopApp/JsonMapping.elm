module DesktopApp.JsonMapping exposing
    ( ObjectMapping
    , encode, decoder
    , object, with, static, mapObject
    , JsonMapping, int, string, bool
    , maybe, list, custom, fromObjectMapping, map
    , customType, variant0, variant1, variant2, variant3, variant4, variant5, Variant, VariantEncoder, VariantDecoder
    )

{-|

@docs ObjectMapping
@docs encode, decoder

@docs object, with, static, mapObject
@docs JsonMapping, int, string, bool
@docs maybe, list, custom, fromObjectMapping, map
@docs customType, variant0, variant1, variant2, variant3, variant4, variant5, Variant, VariantEncoder, VariantDecoder

-}

import Dict
import Json.Decode exposing (Decoder)
import Json.Encode as Json


{-| Represents both how to encode `b` into JSON, and decode `a` from a JSON object.
This is similar to `JsonMapping`, but it allows a pipeline-style API for building up mappings
(see [`object`](#object), [`with`](#with), [`static`](#static)).

Notably this is used with `DesktopApp.program` to specify how to save and load data.
When used in that way, the `encodesFrom` type will be your program's model,
and the `decodesTo` type will be your program's msg (which will be produced when data is loaded).

Also of note: when `a` and `b` are the same it specifies a two-way mapping to and from JSON
(and can then be turned into a `JsonMapping` with [`fromObjectMapping`](#fromObjectMapping)).

-}
type ObjectMapping encodesFrom decodesTo
    = ObjectMapping (encodesFrom -> List ( String, Json.Value )) (Decoder decodesTo)


{-| Representings how to encode `a` to and from JSON.
-}
type JsonMapping a
    = JsonMapping (a -> Json.Value) (Decoder a)


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

TODO: should also take `(b -> a)` ?

-}
mapObject : (a -> b) -> ObjectMapping encodesFrom a -> ObjectMapping encodesFrom b
mapObject f (ObjectMapping fields decode) =
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


{-| Maps an Elm `Int` to and from JSON.
-}
int : JsonMapping Int
int =
    JsonMapping Json.int Json.Decode.int


{-| Maps an Elm `String` to and from JSON.
-}
string : JsonMapping String
string =
    JsonMapping Json.string Json.Decode.string


{-| Maps an Elm `Bool` to and from JSON.
-}
bool : JsonMapping Bool
bool =
    JsonMapping Json.bool Json.Decode.bool


{-| Maps an Elm `Maybe` to and from JSON.
`Nothing` will map to `null`,
and `Just a` will use the given mapping for `a`.

    import DesktopApp.JsonMapping exposing (maybe, int, encode, decoder)
    import Json.Decode exposing (decodeString)

    encode (maybe int) (Just 7)  --> "7"
    encode (maybe int) Nothing  --> "null"

    decodeString (decoder (maybe string)) "\"hi\""  --> Just "hi"
    decodeString (decoder (maybe string)) "null"  --> Nothing

-}
maybe : JsonMapping a -> JsonMapping (Maybe a)
maybe (JsonMapping enc dec) =
    JsonMapping
        (Maybe.map enc >> Maybe.withDefault Json.null)
        (Json.Decode.nullable dec)


{-| Maps an Elm `List` to and from a JSON array.
-}
list : JsonMapping a -> JsonMapping (List a)
list (JsonMapping enc dec) =
    JsonMapping (Json.list enc) (Json.Decode.list dec)


{-| Creates a JsonMapping that uses the given Elm JSON encoder and decoder
-}
custom : (a -> Json.Value) -> Decoder a -> JsonMapping a
custom enc dec =
    JsonMapping enc dec


{-| Transforms a JsonMapping. This requires functions for transforming in each direction
so that both encoding and decoding can be handled.
-}
map : (b -> a) -> (a -> b) -> JsonMapping a -> JsonMapping b
map en de (JsonMapping enc dec) =
    JsonMapping (en >> enc) (Json.Decode.map de dec)


{-| Creates a JsonMapping from an ObjectMapping

This allows you to create JsonMappings that can then be used as nested fields within other ObjectMappings.

    import DesktopApp.JsonMapping exposing (fromObjectMapping, int, object, string, with)

    type alias MyData =
        { name : String
        , admin : Bool
        }

    myDataMapping : JsonMapping MyData
    myDataMapping =
        object MyData
            |> with "name" .name string
            |> with "admin" .admin bool
            |> fromObjectMapping

-}
fromObjectMapping : ObjectMapping a a -> JsonMapping a
fromObjectMapping mapping =
    JsonMapping (encodeValue mapping) (decoder mapping)


{-| Adds a field to an object. It will be represented in both your Elm model and in the JSON.
-}
with :
    String
    -> (encodesFrom -> a)
    -> JsonMapping a
    -> ObjectMapping encodesFrom (a -> decodesTo)
    -> ObjectMapping encodesFrom decodesTo
with name get (JsonMapping toJson fd) (ObjectMapping fields dec) =
    ObjectMapping
        (\x -> ( name, get x |> toJson ) :: fields x)
        (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) dec)


{-| Adds a static field to an object. The field will not be represented in your Elm model,
but this exact field name and string value will be added to the written-out JSON file.
-}
static : String -> JsonMapping a -> a -> ObjectMapping encodesFrom decodesTo -> ObjectMapping encodesFrom decodesTo
static name (JsonMapping enc _) value (ObjectMapping fields dec) =
    ObjectMapping
        (\x -> ( name, enc value ) :: fields x)
        dec



-- TODO: a function to hardcode a parameter into the Elm value which is not in the JSON
-- TODO: ? a function to hardcode a value in the JSON, but also pass it to Elm (maybe not necessary with static and a way to hardcode only into Elm?)


{-| Maps an Elm [custom type](https://guide.elm-lang.org/types/custom_types.html) to and from a JSON object.

`VariantDecoder`s and `VariantEncoder`s are created using the [`variant*`](#variant0) functions (see the example here).

This function returns an ObjectMapping instead of a JsonMapping so that it is possible to have a custom type as the top-level of your persisted data when using `DesktopApp.program`.
If you need a JsonMapping, you can use this with [`fromObjectMapping`](#fromObjectMapping)
(as shown in the example here).

    type MyType
        = NotAuthorized
        | Guest Bool String
        | Employee Int

    myTypeMapping : JsonMapping MyType
    myTypeMapping =
        let
            notAuthorized =
                variant0 "NotAuthorized" NotAuthorized

            guest =
                variant2 "Guest"
                    Guest
                    ( "is_vip", bool )
                    ( "name", string )

            employee =
                variant1 "Employee"
                    Employee
                    ( "employee_id", int )
        in
        customType
            [ notAuthorized.decode
            , guest.decode
            , employeed.decode
            ]
            (\x ->
                case x of
                    NotAuthorized ->
                        notAuthorized.encode

                    Guest isVip name ->
                        guest.encode isVip name

                    Employee id ->
                        employeed.encode id
            )
            |> fromObjectMapping

-}
customType : List (VariantDecoder a) -> (a -> VariantEncoder) -> ObjectMapping a a
customType dec enc =
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
                        -- TODO: it is probably faster to just recurse through the list instead of transforming into a Dict
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


{-| Represents how to map an Elm [custom type](https://guide.elm-lang.org/types/custom_types.html) variant (sometimes also called a "tag", "contructor", or "enum value") to and from a JSON object.
This is different from a JsonMapping because it carries with it information about the name of the variant
and does some tricks with the type system to make the `customType` API as nice as possible.

**Normally you will not need to reference this type directly.** See the example for [`customType`](#customType).

-}
type alias Variant decodesTo encoder =
    { decode : VariantDecoder decodesTo
    , encode : encoder
    }


{-| Represents how to decode an Elm [custom type](https://guide.elm-lang.org/types/custom_types.html) variant from a JSON object.

**Normally you will not need to reference this type directly.** See the example for [`customType`](#customType).

-}
type VariantDecoder decodesTo
    = VariantDecoder
        { tag : String
        , decode : Decoder decodesTo
        }


{-| Represents how to encode an Elm [custom type](https://guide.elm-lang.org/types/custom_types.html) variant to a JSON object.

**Normally you will not need to reference this type directly.** See the example for [`customType`](#customType).

-}
type VariantEncoder
    = VariantEncoder String (List ( String, Json.Value ))


{-| Creates a VarientEncoder and VariantDecoder for an Elm custom type variant that takes no parameters.

See [`customType`](#customType) for an example of how to use the `variant*` functions.

-}
variant0 : String -> decodesTo -> Variant decodesTo VariantEncoder
variant0 name f =
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


{-| Creates a VarientEncoder and VariantDecoder for an Elm custom type variant that takes one parameter.

See [`customType`](#customType) for an example of how to use the `variant*` functions.

-}
variant1 :
    String
    -> (a -> decodesTo)
    -> ( String, JsonMapping a )
    -> Variant decodesTo (a -> VariantEncoder)
variant1 name f ( an, JsonMapping ac ad ) =
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


{-| Creates a VarientEncoder and VariantDecoder for an Elm custom type variant that takes two parameters.

See [`customType`](#customType) for an example of how to use the `variant*` functions.

-}
variant2 :
    String
    -> (a -> b -> decodesTo)
    -> ( String, JsonMapping a )
    -> ( String, JsonMapping b )
    -> Variant decodesTo (a -> b -> VariantEncoder)
variant2 name f ( an, JsonMapping ac ad ) ( bn, JsonMapping bc bd ) =
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


{-| Creates a VarientEncoder and VariantDecoder for an Elm custom type variant that takes three parameters.

See [`customType`](#customType) for an example of how to use the `variant*` functions.

-}
variant3 :
    String
    -> (a -> b -> c -> decodesTo)
    -> ( String, JsonMapping a )
    -> ( String, JsonMapping b )
    -> ( String, JsonMapping c )
    -> Variant decodesTo (a -> b -> c -> VariantEncoder)
variant3 name f ( an, JsonMapping ac ad ) ( bn, JsonMapping bc bd ) ( cn, JsonMapping cc cd ) =
    { decode =
        VariantDecoder
            { tag = name
            , decode =
                Json.Decode.map3 f
                    (Json.Decode.field an ad)
                    (Json.Decode.field bn bd)
                    (Json.Decode.field cn cd)
            }
    , encode =
        \a b c ->
            VariantEncoder
                name
                [ ( an, ac a )
                , ( bn, bc b )
                , ( cn, cc c )
                ]
    }


{-| Creates a VarientEncoder and VariantDecoder for an Elm custom type variant that takes four parameters.

See [`customType`](#customType) for an example of how to use the `variant*` functions.

-}
variant4 :
    String
    -> (a -> b -> c -> d -> decodesTo)
    -> ( String, JsonMapping a )
    -> ( String, JsonMapping b )
    -> ( String, JsonMapping c )
    -> ( String, JsonMapping d )
    -> Variant decodesTo (a -> b -> c -> d -> VariantEncoder)
variant4 name f ( an, JsonMapping ac ad ) ( bn, JsonMapping bc bd ) ( cn, JsonMapping cc cd ) ( dn, JsonMapping dc dd ) =
    { decode =
        VariantDecoder
            { tag = name
            , decode =
                Json.Decode.map4 f
                    (Json.Decode.field an ad)
                    (Json.Decode.field bn bd)
                    (Json.Decode.field cn cd)
                    (Json.Decode.field dn dd)
            }
    , encode =
        \a b c d ->
            VariantEncoder
                name
                [ ( an, ac a )
                , ( bn, bc b )
                , ( cn, cc c )
                , ( dn, dc d )
                ]
    }


{-| Creates a VarientEncoder and VariantDecoder for an Elm custom type variant that takes five parameters.

See [`customType`](#customType) for an example of how to use the `variant*` functions.

-}
variant5 :
    String
    -> (a -> b -> c -> d -> e -> decodesTo)
    -> ( String, JsonMapping a )
    -> ( String, JsonMapping b )
    -> ( String, JsonMapping c )
    -> ( String, JsonMapping d )
    -> ( String, JsonMapping e )
    -> Variant decodesTo (a -> b -> c -> d -> e -> VariantEncoder)
variant5 name f ( an, JsonMapping ac ad ) ( bn, JsonMapping bc bd ) ( cn, JsonMapping cc cd ) ( dn, JsonMapping dc dd ) ( en, JsonMapping ec ed ) =
    { decode =
        VariantDecoder
            { tag = name
            , decode =
                Json.Decode.map5 f
                    (Json.Decode.field an ad)
                    (Json.Decode.field bn bd)
                    (Json.Decode.field cn cd)
                    (Json.Decode.field dn dd)
                    (Json.Decode.field en ed)
            }
    , encode =
        \a b c d e ->
            VariantEncoder
                name
                [ ( an, ac a )
                , ( bn, bc b )
                , ( cn, cc c )
                , ( dn, dc d )
                , ( en, ec e )
                ]
    }
