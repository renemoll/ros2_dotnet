/* Copyright 2016-2018 Esteve Fernandez <esteve@apache.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

using System;

namespace ROS2
{
    public interface IRosMessage
    {
        // must be implemented on deriving types, gets called via reflection
        // (static abstract interface members are not supported yet.)
        // public static abstract IntPtr __GetTypeSupport();
        // public static abstract SafeHandle __CreateMessageHandle();

        void __ReadFromHandle(IntPtr messageHandle);

        void __WriteToHandle(IntPtr messageHandle);
    }

    public interface MessageWithHeader : IRosMessage
    {
        void SetHeaderFrame(string frameID);
        string GetHeaderFrame();
        void UpdateHeaderTime(int sec, uint nanosec);
    }
}
