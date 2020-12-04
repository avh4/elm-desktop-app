module DesktopApp.Menubar exposing (Menubar(..), mapping)

import DesktopApp.JsonMapping as JsonMapping exposing (ObjectMapping, variant0)


type Menubar
    = DefaultMenu
    | NoMenu


mapping : ObjectMapping Menubar Menubar
mapping =
    let
        defaultMenu =
            variant0 "DefaultMenu" DefaultMenu

        noMenu =
            variant0 "NoMenu" NoMenu
    in
    JsonMapping.customType
        [ defaultMenu.decode
        , noMenu.decode
        ]
        (\x ->
            case x of
                DefaultMenu ->
                    defaultMenu.encode

                NoMenu ->
                    noMenu.encode
        )
