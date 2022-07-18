/*
 * CookingFiniteStateMachine.swift
 * Cooking
 *
 * Created by Callum McColl on 6/7/2022.
 * Copyright © 2022 Callum McColl. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgement:
 *
 *        This product includes software developed by Callum McColl.
 *
 * 4. Neither the name of the author nor the names of contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * -----------------------------------------------------------------------
 * This program is free software; you can redistribute it and/or
 * modify it under the above terms or under the terms of the GNU
 * General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/
 * or write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SharedVariables

final class CookingFiniteStateMachine: MachineProtocol, CustomStringConvertible {

    typealias _StateType = MicrowaveState
    typealias Ringlet = MicrowaveRinglet

    var validVars: [String: [Any]] {
        [
            "currentState": [],
            "exitState": [],
            "externalVariables": [],
            "sensors": [],
            "actuators": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "fsmVars": [],
            "initialPreviousState": [],
            "initialState": [],
            "name": [],
            "previousState": [],
            "submachineFunctions": [],
            "submachines": [],
            "suspendedState": [],
            "suspendState": [],
            "buttonPushed": [],
            "doorOpen": [],
            "timeLeft": [],
            "motor": [],
            "onState": [],
            "$__lazy_storage_$_currentState": [],
            "$__lazy_storage_$_initialState": [],
            "$__lazy_storage_$_onState": []
        ]
    }

    var description: String {
        "\(KripkeStatePropertyList(self))"
    }

    var computedVars: [String: Any] {
        return [
            "sensors": Dictionary(uniqueKeysWithValues: sensors.map { ($0.name, $0.val) }),
            "actuators": Dictionary(uniqueKeysWithValues: actuators.map { ($0.name, $0.val) }),
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }

    var doorOpen: InMemoryVariable<Bool>

    var timeLeft: InMemoryVariable<Bool>

    var motor: InMemoryVariable<Bool>

    var sensors: [AnySnapshotController]{
        get {
            [AnySnapshotController(doorOpen), AnySnapshotController(timeLeft)]
        } set {
            if let val = newValue.first(where: { $0.name == doorOpen.name })?.val {
                doorOpen.val = val as! Bool
            }
            if let val = newValue.first(where: { $0.name == timeLeft.name })?.val {
                timeLeft.val = val as! Bool
            }
        }
    }

    var actuators: [AnySnapshotController] {
        get {
            [AnySnapshotController(motor)]
        } set {
            if let val = newValue.first(where: { $0.name == motor.name })?.val {
                motor.val = val as! Bool
            }
        }
    }

    var externalVariables: [AnySnapshotController] = []

    var name: String

    lazy var initialState: MicrowaveState = {
        CallbackMicrowaveState(
            "Not_Cooking",
            transitions: [Transition(onState) { [unowned self] _ in !self.doorOpen.val && self.timeLeft.val }],
            snapshotSensors: [doorOpen.name, timeLeft.name],
            snapshotActuators: [motor.name],
            onEntry: { [unowned self] in self.motor.val = false }
        )
    }()

    lazy var onState: MicrowaveState = {
        CallbackMicrowaveState(
            "Cooking",
            snapshotSensors: [doorOpen.name, timeLeft.name],
            snapshotActuators: [motor.name],
            onEntry: { [unowned self] in self.motor.val = true }
        )
    }()

    lazy var currentState: MicrowaveState = { initialState }()

    var previousState: MicrowaveState = EmptyMicrowaveState("previous")

    var suspendedState: MicrowaveState? = nil

    var suspendState: MicrowaveState = EmptyMicrowaveState("suspend")

    var exitState: MicrowaveState = EmptyMicrowaveState("exit", snapshotSensors: [])

    var submachines: [CookingFiniteStateMachine] = []

    var initialPreviousState: MicrowaveState = EmptyMicrowaveState("previous")

    var ringlet = MicrowaveRinglet(previousState: EmptyMicrowaveState("previous"))

    func clone() -> CookingFiniteStateMachine {
        let fsm = CookingFiniteStateMachine(name: name, doorOpen: doorOpen.clone(), timeLeft: timeLeft.clone(), motor: motor)
        fsm.name = name
        if currentState.name == initialState.name {
            fsm.currentState = fsm.initialState
        } else if currentState.name == onState.name {
            fsm.currentState = fsm.onState
        }
        if previousState.name == initialState.name {
            fsm.previousState = fsm.initialState
        } else if previousState.name == onState.name {
            fsm.previousState = fsm.onState
        }
        fsm.motor = motor.clone()
        fsm.ringlet = ringlet.clone()
        if fsm.ringlet.previousState.name == initialState.name {
            fsm.ringlet.previousState = fsm.initialState
        } else if fsm.ringlet.previousState.name == onState.name {
            fsm.ringlet.previousState = fsm.onState
        }
        return fsm
    }

    init(name: String, doorOpen: InMemoryVariable<Bool>, timeLeft: InMemoryVariable<Bool>, motor: InMemoryVariable<Bool>) {
        self.name = name
        self.doorOpen = doorOpen
        self.timeLeft = timeLeft
        self.motor = motor
        self.onState.addTransition(MicrowaveTransition(UnownedTransition(initialState) { [unowned self] _ in self.doorOpen.val || !self.timeLeft.val }))
    }

}
