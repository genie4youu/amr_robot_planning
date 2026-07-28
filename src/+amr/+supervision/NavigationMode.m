classdef NavigationMode < Simulink.IntEnumType
    %NAVIGATIONMODE Discrete navigation-supervision phases.

    enumeration
        NavIdle(0)
        Planning(1)
        Tracking(2)
        Replanning(3)
        Recovery(4)
        NavFailed(5)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.NavigationMode.NavIdle;
        end

        function description = getDescription()
            description = 'AMR navigation supervision mode';
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
