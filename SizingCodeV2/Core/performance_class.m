classdef performance_class < handle % <--- Inheriting from handle allows in-place updates (memory based/pointers)

    % This evaluate point performance at a give h, M, Cl, and Weight
    % The power of this function is robustness to recalculating any expensive analyisis. It saves all the data and recrusively works through
        % them to make use any calculated values. This is different from old code that would recalculate CD over and over

    % WARNING: Be VERY VERY careful about making sure ids are unique

    properties
        model % link to the model. Stays connected through memory
        data % struct storing key performance info as it is generated
    end

    methods
        % INITIALIZATION
        function obj = performance_class(model)
            obj.model = model;
        end

        %% HELPERS
        function obj = clear_data(obj)
            obj.data = struct();
        end
        function bool = hasData(obj, field)
            bool = isfield(obj.data, field);
        end
        function out = simpleUpdateCheck(obj, id, handle)
            if obj.hasData(id)
                out = obj.data.(id);
            else
                obj.data.(id) = handle();
                out = obj.data.(id);
            end
        end

        %% ACTUAL MAIN FUNCTIONS

        % Total CD
        function out = CD(obj)
            out = obj.simpleUpdateCheck('CD', @() obj.model.CD0 + obj.model.CDi + obj.model.CDw + obj.model.CDp);
        end

        % Physical Forces
        function out = Drag(obj)
            % N
            out =  obj.simpleUpdateCheck('Drag', @() obj.model.geom.ref_area.v * obj.model.cond.qinf.v .* obj.CD );
        end

        % Lift Over Drag
        function out = LD(obj)
            out =  obj.simpleUpdateCheck('LD', @() obj.model.cond.CL.v ./ obj.CD );
        end

        function out = Lift(obj)
            % N
            out =  obj.simpleUpdateCheck('Lift', @() obj.model.geom.ref_area.v * obj.model.cond.qinf.v .* obj.model.cond.CL.v );
        end

        % Propulsion
        function out = TA(obj)
            % N
            if obj.hasData('TA')
                out = obj.data.('TA');
            else
                out = obj.model.PROP;
                out = out(1, :);
            end
        end
        function out = TSFC(obj)
            % sec
            if obj.hasData('TSFC')
                out = obj.data.('TSFC');
            else
                out = obj.model.PROP;
                out = out(2,:);
            end
        end
        function out = mdotf(obj)
            % kg/s
            out = obj.TA .* obj.TSFC;
        end
        % Actually called performance
        function out = ExcessThrust(obj)
            % N
            out =  obj.simpleUpdateCheck('ExcessThrust', @() obj.TA - obj.Drag );
        end
        function out = ExcessPower(obj)
            % m/s
            out =  obj.simpleUpdateCheck('ExcessPower', @() obj.model.cond.vel.v .* obj.ExcessThrust ./ obj.model.cond.W.v);
        end
        function out = TurnRate(obj)
            % deg/s - is not neccessarily a level turn
            out =  obj.simpleUpdateCheck('TurnRate', @() rad2deg( obj.model.cond.n.v .* obj.model.settings.g_const ./ obj.model.cond.vel.v ) );
        end
        function out = LevelTurnRate(obj)
            % deg/s - holding a level turn
            out =  obj.simpleUpdateCheck('LevelTurnRate', @() rad2deg( sqrt( obj.model.cond.n.v .* obj.model.cond.n.v - 1) * obj.model.settings.g_const ./ obj.model.cond.vel.v ) );
        end
        function out = ClimbAngle(obj, EP)

            % EP -> the amount of excess power that should be 'left over' (for axial accelleration) in the climb
            if nargin < 2
                EP = 0;
            end

            % This also acts as glide angle if TA = 0
            % If there is a climb angle between 0 and 90 that the plane is not accellerating, that is returned
            % Otherwise, 90 is returned
            % If ExcesssThrust is less than 0, it instead gives a negative climb angle, which is the 'glide' angle to have no accelleration
            % Note that if turn load factor is not 1, this does not make much sense

            out =  obj.simpleUpdateCheck('ClimbAngle', @() ClimbAngleHepler(obj, EP) );
        end
            function out = ClimbAngleHepler(obj, EP)
                % So that there can be a update check

                % EP = (T - D) * v / W
                ET = EP .* obj.model.cond.W.v ./ obj.model.cond.vel.v; % excess thrust
                
                % This is a vectorized version of the if statements
                climbing_straight_up = obj.ExcessPower - EP > obj.model.cond.vel.v;
                going_straight_down = obj.ExcessThrust - ET + obj.model.cond.W.v < 0;
                % standard = ~climbing_straight_up .* ~going_straight_down;

                out = asind( (obj.TA - obj.Drag - ET)./obj.model.cond.W.v);
                out(climbing_straight_up) = 90;
                out(going_straight_down) = -90;

                % if obj.ExcessPower > obj.model.cond.vel.v % we can climb straight up
                %    out = 90;
                % elseif obj.ExcessThrust + obj.model.cond.W.v < 0
                %     % there is so much drag we are decellerating when pointing straight down
                %     out = -90;
                % else
                %     % Solve for the right climb angle theta so that axial forces are balanced
                %     % TA = Drag + weight * sin(theta)
                %     out =  asind( (obj.TA - obj.Drag)./obj.model.cond.W.v);
                % end
            end
        function out = e_osw(obj)
            % return the oswlad efficency
            out =  obj.simpleUpdateCheck('LevelTurnRate', @() obj.model.cond.CL.v.^2 ./ (pi * obj.model.geom.wing.AR.v * obj.model.CDi) );
        end
        function out = AxialAccelleration(obj, EP)
            % in Gs

            % If EP is provided, that is the axial accelleration possible given some climb rate in m/s
            if nargin < 2
                EP = 0;
            end
            ET = EP .* obj.model.cond.W.v ./ obj.model.cond.vel.v; % excess thrust

            out = obj.simpleUpdateCheck('AxialAccelleration', @() (obj.ExcessThrust - ET) ./ obj.model.cond.W.v );
        end
        function out = Rbar(obj)
            % Kinda a non-physical term. When minimized it defines the best cruise point
            out = obj.simpleUpdateCheck('Rbar', @() obj.RbarHelper );
        end
            function out = RbarHelper(obj)
                % slightly more stable method of getting mdotf for level flight
                
                Rbar = obj.TSFC .* obj.Drag ./ obj.model.cond.vel.v;
                % min_alt = 100; % in meters. Passed this it starts to provide a large amount of weighting to keep you from hitting the ground
                % R = 1E-4;
                % Rbar = Rbar + R * max(0, (min_alt - obj.model.cond.h.v)/min_alt);
                out = Rbar;
            end
    end
end