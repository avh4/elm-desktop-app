module DesktopApp.Menu exposing (MenuAction(..), MenuItem(..), MenuItemRole(..), map, mapMenuAction, mapMenuItem, menuItemToJson)

import DesktopApp.JsonMapping as JsonMapping exposing (JsonMapping, variant0, variant1, variant2, variant3)
import Json.Encode


map : (a -> b) -> List (MenuItem a) -> List (MenuItem b)
map f =
    List.map (mapMenuItem f)


type MenuItem msg
    = MenuItem
        { label : String
        , action : MenuAction msg

        --, accelerator : Maybe Accelerator
        , enabled : Bool
        }
    | SubMenu
        { label : String
        , items : List (MenuItem msg)
        }
    | Separator


mapMenuItem : (a -> b) -> MenuItem a -> MenuItem b
mapMenuItem f menuItem =
    case menuItem of
        MenuItem record ->
            MenuItem
                { label = record.label
                , action = mapMenuAction f record.action
                , enabled = record.enabled
                }

        SubMenu record ->
            SubMenu
                { label = record.label
                , items = map f record.items
                }

        Separator ->
            Separator


menuItemToJson : MenuItem Json.Encode.Value -> Json.Encode.Value
menuItemToJson menuItem =
    case menuItem of
        MenuItem record ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "normal" )
                , ( "label", Json.Encode.string record.label )
                , ( "enabled", Json.Encode.bool record.enabled )
                ]

        SubMenu record ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "submenu" )
                , ( "label", Json.Encode.string record.label )
                , ( "submenu", Json.Encode.list menuItemToJson record.items )
                ]

        Separator ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "separator" )
                ]



--
--menuItemMapping : () -> JsonMapping (MenuItem String)
--menuItemMapping () =
--    let
--        menuItem =
--            variant3 "MenuItem"
--                (\a b c -> MenuItem { label = a, action = b, enabled = c })
--                ( "label", JsonMapping.string )
--                ( "action", menuActionMapping )
--                ( "enabled", JsonMapping.bool )
--
--        subMenu =
--            variant2 "SubMenu"
--                (\a b -> SubMenu { label = a, items = b })
--                ( "label", JsonMapping.string )
--                ( "items", JsonMapping.list (menuItemMapping ()) )
--
--        separator =
--            variant0 "Separator" Separator
--    in
--    JsonMapping.customType
--        [ menuItem.decode
--        , subMenu.decode
--        , separator.decode
--        ]
--        (\x ->
--            case x of
--                MenuItem config ->
--                    menuItem.encode config.label config.action config.enabled
--
--                SubMenu config ->
--                    subMenu.encode config.label config.items
--
--                Separator ->
--                    separator.encode
--        )
--        |> JsonMapping.fromObjectMapping


type MenuAction msg
    = Custom msg
    | Predefined MenuItemRole


mapMenuAction : (a -> b) -> MenuAction a -> MenuAction b
mapMenuAction f menuAction =
    case menuAction of
        Custom msg ->
            Custom (f msg)

        Predefined menuItemRole ->
            Predefined menuItemRole



--
--menuActionMapping : JsonMapping (MenuAction String)
--menuActionMapping =
--    let
--        custom =
--            variant1 "Custom"
--                Custom
--                ( "msg", JsonMapping.string )
--
--        predefined =
--            variant1 "Predefined"
--                Predefined
--                ( "role", JsonMapping.string )
--                ( "items", JsonMapping.list (menuItemMapping ()) )
--
--        separator =
--            variant0 "Separator" Separator
--    in
--    JsonMapping.customType
--        [ menuItem.decode
--        , subMenu.decode
--        , separator.decode
--        ]
--        (\x ->
--            case x of
--                MenuItem config ->
--                    menuItem.encode config.label config.action config.enabled
--
--                SubMenu config ->
--                    subMenu.encode config.label config.items
--
--                Separator ->
--                    separator.encode
--        )
--        |> JsonMapping.fromObjectMapping
--


type MenuItemRole
    = Undo
    | Redo
    | Cut
    | Copy
    | Paste



--| ...
