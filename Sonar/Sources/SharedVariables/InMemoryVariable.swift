/*
 * InMemoryContainer.swift
 * VerificationTests
 *
 * Created by Callum McColl on 19/10/20.
 * Copyright © 2020 Callum McColl. All rights reserved.
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
import swiftfsm

fileprivate var cache: [String: Any] = [:]

public final class InMemoryVariable<T: ExternalVariables>: ExternalVariablesContainer, Snapshotable, KripkeVariablesModifier, Cloneable {
    
    public var validVars: [String: [Any?]] {
        [
            "rawName": []
        ]
    }

    public let rawName: String
    
    public let name: String
    
    public var val: T
    
    public init(name: String, initialValue: T) {
        self.rawName = name
        self.name = "InMemoryVariable-" + name
        self.val = initialValue
        cache[self.name] = self.val
    }
    
    public func saveSnapshot() {
        cache[name] = val
    }
    
    public func takeSnapshot() {
        self.val = cache[name] as? T ?? self.val
    }

    public func clone() -> InMemoryVariable<T> {
        InMemoryVariable<T>(name: self.rawName, initialValue: ((self.val as? Cloneable)?.clone() as? T) ?? self.val)
    }
    
}

extension InMemoryVariable where T == Bool {

    public static var buttonPushed: InMemoryVariable<Bool> {
        InMemoryVariable<Bool>(name: "buttonPushed", initialValue: false)
    }

    public static var doorOpen: InMemoryVariable<Bool> {
        InMemoryVariable<Bool>(name: "doorOpen", initialValue: false)
    }

    public static var timeLeft: InMemoryVariable<Bool> {
        InMemoryVariable<Bool>(name: "timeLeft", initialValue: false)
    }

    public static var light: InMemoryVariable<Bool> {
        InMemoryVariable<Bool>(name: "light", initialValue: false)
    }

    public static var motor: InMemoryVariable<Bool> {
        InMemoryVariable<Bool>(name: "motor", initialValue: false)
    }

    public static var sound: InMemoryVariable<Bool> {
        InMemoryVariable<Bool>(name: "sound", initialValue: false)
    }

}

extension InMemoryVariable where T == MicrowaveStatus {

    public static var status: InMemoryVariable<MicrowaveStatus> {
        InMemoryVariable<MicrowaveStatus>(
            name: "status",
            initialValue: MicrowaveStatus(
                buttonPushed: false,
                doorOpen: false,
                timeLeft: false
            )
        )
    }

}
