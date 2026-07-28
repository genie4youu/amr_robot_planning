classdef MissionMode < Simulink.IntEnumType
    %MISSIONMODE Discrete phases of an AMR transport mission.

    enumeration
        Idle(0)
        ValidateJob(1)
        NavigatePickup(2)
        Loading(3)
        NavigateDropoff(4)
        Unloading(5)
        ReturnHome(6)
        Suspended(7)
        Aborting(8)
        Completed(9)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.MissionMode.Idle;
        end

        function description = getDescription()
            description = 'AMR mission execution mode';
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
