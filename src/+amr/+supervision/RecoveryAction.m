classdef RecoveryAction < Simulink.IntEnumType
    %RECOVERYACTION Bounded navigation-recovery requests.

    enumeration
        None(0)
        Replan(1)
        ClearLocalMap(2)
        RotateInPlace(3)
        ReverseCreep(4)
        RequestAssistance(5)
        AbortMission(6)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.RecoveryAction.None;
        end

        function description = getDescription()
            description = 'AMR supervisor recovery action';
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
