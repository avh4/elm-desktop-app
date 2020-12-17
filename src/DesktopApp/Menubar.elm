module DesktopApp.Menubar exposing (Menubar(..), toJson)

import DesktopApp.JsonMapping as JsonMapping exposing (ObjectMapping, variant0, variant1)
import DesktopApp.Menu as Menu exposing (MenuItem)
import Json.Encode


type Menubar msg
    = DefaultMenu
    | NoMenu
    | CustomMenu (List (MenuItem msg))


toJson : (msg -> Json.Encode.Value) -> Menubar msg -> Json.Encode.Value
toJson msgToJson menubar =
    case menubar of
        DefaultMenu ->
            Json.Encode.string "DefaultMenu"

        NoMenu ->
            Json.Encode.string "NoMenu"

        CustomMenu menuItems ->
            Json.Encode.list Menu.menuItemToJson (Menu.map msgToJson menuItems)



--
--mapping : ObjectMapping (Menubar Never) (Menubar Never)
--mapping =
--    let
--        defaultMenu =
--            variant0 "DefaultMenu" DefaultMenu
--
--        noMenu =
--            variant0 "NoMenu" NoMenu
--
--        customMenu =
--            variant1 "CustomMenu"
--                CustomMenu
--                ( "items", JsonMapping.list Menu.menuItemMapping )
--    in
--    JsonMapping.customType
--        [ defaultMenu.decode
--        , noMenu.decode
--        , customMenu.decode
--        ]
--        (\x ->
--            case x of
--                DefaultMenu ->
--                    defaultMenu.encode
--
--                NoMenu ->
--                    noMenu.encode
--
--                CustomMenu items ->
--                    customMenu.encode items
--        )
