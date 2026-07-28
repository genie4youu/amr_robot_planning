classdef SafetyMode < Simulink.IntEnumType
    %SAFETYMODE Discrete protective-motion states.

    enumeration
        Clear(0)
        Slowdown(1)
        ProtectiveStop(2)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.SafetyMode.Clear;
        end

        function description = getDescription()
            description = 'AMR protective-motion safety mode';
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
