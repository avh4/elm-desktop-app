module DesktopApp.JsonMappingSpec exposing (all)

import DesktopApp.JsonMapping as JsonMapping exposing (ObjectMapping, bool, customType, int, list, maybe, object, static, string, variant0, variant1, variant2, with)
import Expect
import Json.Decode
import Test exposing (..)


check : String -> ObjectMapping a a -> a -> String -> Test
check name mapping elmValue jsonString =
    describe name
        [ test "encodes" <|
            \() ->
                JsonMapping.encodeString mapping elmValue
                    |> Expect.equal jsonString
        , test "decodes" <|
            \() ->
                Json.Decode.decodeString (JsonMapping.decoder mapping) jsonString
                    |> Expect.equal (Ok elmValue)
        ]


type alias Single a =
    { a : a
    }


type alias Double a b =
    { a : a
    , b : b
    }


type CustomType
    = Zero
    | One Int
    | Two String Bool


all : Test
all =
    describe "DesktopApp.JsonMapping"
        [ check "empty object"
            (object {})
            {}
            """{}"""
        , check "object with int"
            (object Single
                |> with "a" .a int
            )
            { a = 9 }
            """{"a":9}"""
        , check "object with string"
            (object Single
                |> with "a" .a string
            )
            { a = "Hi, mom!" }
            """{"a":"Hi, mom!"}"""
        , check "object with bool"
            (object Single
                |> with "a" .a bool
            )
            { a = True }
            """{"a":true}"""
        , check "adding static data"
            (object Single
                |> static "version" 1 int
                |> with "a" .a string
            )
            { a = "submitted" }
            """{"version":1,"a":"submitted"}"""
        , check "object with multiple fields"
            (object Double
                |> with "a" .a int
                |> with "b" .b bool
            )
            { a = 7, b = False }
            """{"a":7,"b":false}"""
        , check "object with maybe"
            (object Double
                |> with "a" .a (maybe int)
                |> with "b" .b (maybe int)
            )
            { a = Just 88, b = Nothing }
            """{"a":88,"b":null}"""
        , check "object with list"
            (object Single
                |> with "a" .a (list string)
            )
            { a = [ "1", "2", "3" ] }
            """{"a":["1","2","3"]}"""
        , describe "custom type" <|
            let
                zero =
                    variant0 "Zero" Zero

                one =
                    variant1 "One"
                        One
                        ( "a", int )

                two =
                    variant2 "Two"
                        Two
                        ( "a", string )
                        ( "b", bool )

                mapping =
                    customType
                        [ zero.decode, one.decode, two.decode ]
                        (\x ->
                            case x of
                                Zero ->
                                    zero.encode

                                One a ->
                                    one.encode a

                                Two a b ->
                                    two.encode a b
                        )
            in
            [ check "variant with no args"
                mapping
                Zero
                """{"$":"Zero"}"""
            , check "variant with one arg"
                mapping
                (One 6)
                """{"$":"One","a":6}"""
            , check "variant with two args"
                mapping
                (Two "x" True)
                """{"$":"Two","a":"x","b":true}"""
            ]
        ]
