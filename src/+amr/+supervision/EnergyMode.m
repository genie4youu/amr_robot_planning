classdef EnergyMode < Simulink.IntEnumType
    %ENERGYMODE Discrete battery and charging states.

    enumeration
        Normal(0)
        Low(1)
        Critical(2)
        GoToCharger(3)
        Charging(4)
    end

    methods (Static)
        function value = getDefaultValue()
            value = amr.supervision.EnergyMode.Normal;
        end

        function description = getDescription()
            description = 'AMR energy supervision mode';
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
