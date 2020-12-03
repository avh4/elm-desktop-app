module DesktopAppHelper exposing (..)

import DesktopApp.Testable as DesktopApp
import Json.Encode
import ProgramTest
import SimulatedEffect.Cmd
import SimulatedEffect.Ports


simulateAllEffects : ( cmd, List DesktopApp.Effect ) -> ProgramTest.SimulatedEffect msg
simulateAllEffects ( _, effects ) =
    SimulatedEffect.Cmd.batch (List.map simulateEffect effects)


simulateEffect : DesktopApp.Effect -> ProgramTest.SimulatedEffect msg
simulateEffect effect =
    case effect of
        DesktopApp.WriteUserData content ->
            SimulatedEffect.Ports.send "writeUserData" (Json.Encode.string content)

        DesktopApp.LoadUserData ->
            SimulatedEffect.Ports.send "loadUserData" Json.Encode.null
