classdef FaultReason < Simulink.IntEnumType
    %FAULTREASON Stable diagnostic reasons for supervisor decisions.

    enumeration
        None(0)
        EmergencyStop(1)
        SafetySensorStale(2)
        LocalizationInvalid(3)
        PlannerTimeout(4)
        RecoveryExhausted(5)
        DriveFault(6)
        CommunicationLost(7)
        PayloadTimeout(8)
        BatteryCritical(9)
        InvalidJob(10)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.FaultReason.None;
        end

        function description = getDescription()
            description = 'AMR supervisor diagnostic reason';
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
