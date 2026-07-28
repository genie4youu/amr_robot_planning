classdef LifecycleMode < Simulink.IntEnumType
    %LIFECYCLEMODE Top-level AMR supervisor lifecycle states.

    enumeration
        PowerOff(0)
        Boot(1)
        Operational(2)
        ControlledShutdown(3)
        FaultLatched(4)
        EmergencyStopLatched(5)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.LifecycleMode.PowerOff;
        end

        function description = getDescription()
            description = 'Top-level AMR supervisor lifecycle mode';
        end

        function scope = getDataScope()
            scope = 'Auto';
        end

        function header = getHeaderFile()
            header = '';
        end

        function flag = addClassNameToEnumNames()
            flag = true;
        end
    end
end
