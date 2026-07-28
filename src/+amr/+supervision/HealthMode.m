classdef HealthMode < Simulink.IntEnumType
    %HEALTHMODE Discrete health-monitoring states.

    enumeration
        Healthy(0)
        Degraded(1)
        FaultRequest(2)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.HealthMode.Healthy;
        end

        function description = getDescription()
            description = 'AMR health supervision mode';
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
