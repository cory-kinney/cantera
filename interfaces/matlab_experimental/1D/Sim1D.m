classdef Stack < handle

    properties
        stID
        domains
    end

    methods
        %% Stack class constructor

        function s = Stack(domains)
            % A stack object is a container for one-dimensional domains,
            % which are instances of class Domain1D. The domains are of two
            % types - extended domains, and connector domains.
            %
            % :parameter domains:
            %    Vector of domain instances.
            % :return:
            %    Instance of class 'Stack'.

            checklib;

            s.stID = -1;
            s.domains = domains;
            if nargin == 1
                nd = length(domains);
                ids = zeros(1, nd);
                for n=1:nd
                    ids(n) = domains(n).domID;
                end
                s.stID = calllib(ct, 'sim1D_new', nd, ids);
            else
                help(Stack);
                error('Wrong number of :parameters.');
            end
%             if s.stID < 0
%                 error(geterr);
%             end
        end

        %% Utility Methods

        function clear(s)
            % Delete the Sim1D object

            calllib(ct, 'sim1D_del', s.stID);
        end

        function display(s, fname)
            % Show all domains.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter fname:
            %    File to write summary to. If omitted, output is to the
            %    command window.

            if nargin == 1
                fname = '-';
            end
            calllib(ct, 'sim1D_showSolution', s.stID, fname);
        end

        %% Stack Methods

        function n = stackIndex(s, name)
            % Get the index of a domain in a stack given its name.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter name:
            %    If double, the value is :returned. Otherwise, the name is
            %    looked up and its index is :returned.
            % :return:
            %    Index of domain.

            if isa(name, 'double')
                n = name;
            else
                n = calllib(ct, 'sim1D_domainIndex', s.stID, name);
                if n >= 0
                    n = n+1;
                else
                    error('Domain not found');
                end
            end
        end

        function getInitialSoln(s)
            % Get the initial solution.

            calllib(ct, 'sim1D_getInitialSoln', s.stID);
        end

        function z = grid(s, name)
            % Get the grid in one domain.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter name:
            %    Name of the domain for which the grid should be retrieved.
            % :return:
            %    The grid in domain name.

            n = s.stackIndex(name);
            d = s.domains(n);
            z = d.gridPoints;
        end

        function plotSolution(s, domain, component)
            % Plot a specified solution component.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter domain:
            %    Name of domain from which the component should be
            %    retrieved.
            % :parameter component:
            %    Name of the component to be plotted.

            n = s.stackIndex(domain);
            d = s.domains(n);
            z = d.gridPoints;
            x = s.solution(domain, component);
            plot(z, x);
            xlabel('z (m)');
            ylabel(component);
        end

        function r = resid(s, domain, rdt, count)
            % Get the residuals.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter domain:
            %    Name of the domain.
            % :parameter rdt:
            % :parameter count:
            % :return:

            if nargin == 2
                rdt = 0.0;
                count = 0;
            end

            idom = s.stackIndex(domain);
            d = s.domains(idom);

            nc = d.nComponents;
            np = d.nPoints;

            r = zeros(nc, np);
            calllib(ct, 'sim1D_eval', s.stID, rdt, count);
            for m = 1:nc
                for n = 1:np
                    r(m, n) = calllib(ct, 'sim1D_workValue', ...
                                      s.stID, idom - 1, m - 1, n - 1);
                end
            end
        end

        function restore(s, fname, id)
            % Restore a previously-saved solution.
            % This method can be used ot provide an initial guess for the
            % solution.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter fname:
            %    File name of an XML file containing solution info.
            % :parameter id:
            %    ID of the element that should be restored.

            calllib(ct, 'sim1D_restore', s.stID, fname, id)
        end

        function saveSoln(s, fname, id, desc)
            % Save a solution to a file.
            % The output file is in a format that can be used by 'restore'.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter fname:
            %    File name where XML file should be written.
            % :parameter id:
            %    ID to be assigned to the XMl element when it is written.
            % :parameter desc:
            %    Description to be written to the output file.

            if nargin == 1
                fname = 'soln.xml';
                id = 'solution';
                desc = '--';
            elseif nargin == 2
                id = 'solution';
                desc = '--';
            elseif nargin == 3
                desc = '--';
            end
            calllib(ct, 'sim1D_save', s.stID, fname, id, desc);
        end

        function setFixedTemperature(s, T)
            % Set the temperature used to fix the spatial location of a
            % freely propagating flame.
            %
            % :parameter T:
            %    Double Temperature to be set. Unit: K.

            if T <= 0
                error('temperature must be positive');
            end
            calllib(ct, 'sim1D_setFixedTemperature', s.stID, T);
        end

        function setFlatProfile(s, domain, comp, v)
            % Set a component to a value across the entire domain.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter domain:
            %    Integer ID of the domain.
            % :parameter comp:
            %    Component to be set.
            % :parameter v:
            %    Double value to be set.

            calllib(ct, 'sim1D_setFlatProfile', s.stID, ...
                    domain - 1, comp - 1, v);
        end

        function setGridMin(s, domain, gridmin)
            % Set the minimum grid spacing on domain.
            %
            % :parameter domain:
            %    Integer ID of the domain.
            % :parameter gridmin:
            %    Double minimum grid spacing.

            calllib(ct, 'sim1D_setGridMin', s.stID, domain-1, gridmin);
        end

        function setMaxJacAge(s, ss_age, ts_age)
            % Set the number of times the Jacobian will be used before it
            % is recomputed.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter ss_age:
            %    Maximum age of the Jacobian for steady state analysis.
            % :parameter ts_age:
            %    Maximum age of the Jacobian for transient analysis. If not
            %    specified, deftauls to 'ss_age'.

            if nargin == 2
                ts_age = ss_age;
            end
            calllib(ct, 'sim1D_setMaxJacAge', s.stID, ss_age, ts_age);
        end

        function setProfile(s, name, comp, p)
            % Specify a profile for one component,
            %
            % The solution vector values for this component will be
            % linearly interpolated from the discrete function defined by
            % p(:, 1) vs p(:, 2).
            % Note that "p(1, 1) = 0.0" corresponds to the leftmost grid
            % point in the specified domain, and "p(1, n) = 1.0"
            % corresponds to the rightmost grid point. This method can be
            % called at any time, but is usually used to set the initial
            % guess for the solution.
            %
            % Example (assuming 's' is an instance of class 'Stack'):
            %    >> zr = [0.0, 0.1, 0.2, 0.4, 0.8, 1.0];
            %    >> v = [500, 650, 700, 730, 800, 900];
            %    >> s.setProfile(1, 2, [zr, v]);
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter name:
            %    Domain name.
            % :parameter comp:
            %    Component number.
            % :parameter p:
            %    n x 2 array, whose columns are the relative (normalized)
            %    positions and the component values at those points. The
            %    number of positions 'n' is arbitrary.

            if isa(name, 'double')
                n = name;
            else
                n = s.domainIndex(name);
            end

            d = s.domains(n);

            if isa(comp, 'double') || isa(comp, 'cell')
                c = comp;
            elseif isa(comp, 'char')
                c = {comp};
            else
                error('Wrong type.');
            end

            np = length(c);
            sz = size(p);
            if sz(1) == np + 1;
                for j = 1:np
                    ic = d.componentIndex(c{j});
                    calllib(ct, 'sim1D_setProfile', s.stID, ...
                            n - 1, ic - 1, sz(1), p(1, :), sz(1), p(j+1, :));
                end
            elseif sz(2) == np + 1;
                ic = d.componentIndex(c{j});
                calllib(ct, 'sim1D_setProfile', s.stID, ...
                        n - 1, ic - 1, sz(2), p(:, 1), sz(2), p(:, j+1));
            else
                error('Wrong profile shape.');
            end
        end

        function setRefineCriteria(s, n, ratio, slope, curve, prune)
            % Set the criteria used to refine the grid.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter ratio:
            %    Maximum size ratio between adjacent cells.
            % :parameter slope:
            %    Maximum relative difference in value between adjacent
            %    points.
            % :parameter curve:
            %    Maximum relative difference in slope between adjacent
            %    cells.
            % :parameter prune:
            %    Minimum value for slope or curve for which points will be
            %    retained or curve value is below prune for all components,
            %    it will be deleted, unless either neighboring point is
            %    already marked for deletion.

            if nargin < 3
                ratio = 10.0;
            end
            if nargin < 4
                slope = 0.8;
            end
            if nargin < 5
                curve = 0.8;
            end
            if nargin < 6
                prune = -0.1;
            end
            calllib(ct, 'sim1D_setRefineCriteria', s.stID, ...
                    n - 1, ratio, slope, curve, prune);
        end

        function setTimeStep(s, stepsize, steps)
            % Specify a sequence of time steps.
            %
            % :parameter stepsize:
            %    Initial step size.
            % :parameter steps:
            %    Vector of number of steps to take before re-attempting
            %    solution of steady-state problem.
            %    For example, steps = [1, 2, 5, 10] would cause one time
            %    step to be taken first time the steady-state solution
            %    attempted. If this failed, two time steps would be taken.

            calllib(ct, 'sim1D_TimeStep', s.stID, ...
                    stepsize, length(steps), steps);
        end

        function setValue(s, n, comp, localPoints, v)
            % Set the value of a single entry in the solution vector.
            %
            % Example (assuming 's' is an instance of class 'Stack'):
            %
            %    setValue(s, 3, 5, 1, 5.6);
            %
            % This sets component 5 at the leftmost point (local point 1)
            % in domain 3 to the value 5.6. Note that the local index
            % always begins at 1 at the left of each domain, independent of
            % the global index of the point, wchih depends on the location
            % of this domain in the stack.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter n:
            %    Domain number.
            % :parameter comp:
            %    Component number.
            % :parameter localPoints:
            %    Local index of the grid point in the domain.
            % :parameter v:
            %    Value to be set.

            calllib(ct, 'sim1D_setValue', s.stID, ...
                    n - 1, comp -  1, localPoints - 1, v);
        end

        function x = solution(s, domain, component)
            % Get a solution component in one domain.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter domain:
            %    String name of the domain from which the solution is
            %    desired.
            % :parameter component:
            %    String component for which the solution is desired. If
            %    omitted, solution for all of the components will be
            %    :returned in an 'nPoints' x 'nComponnts' array.
            % :return:
            %    Either an 'nPoints' x 1 vector, or 'nPoints' x
            %    'nCOmponents' array.

            idom = s.stackIndex(domain);
            d = s.domains(idom);
            np = d.nPoints;
            if nargin == 3
                icomp = d.componentIndex(component);
                x = zeros(1, np);
                for n = 1:np
                    x(n) = calllib(ct, 'sim1D_value', s.stID, ...
                                   idom - 1, icomp - 1, n - 1);
                end
            else
                nc = d.nComponents;
                x = zeros(nc, np);
                for m = 1:nc
                    for n = 1:np
                        x(m, n) = calllib(ct, 'sim1D_value', s.stID, ...
                                          idom - 1, m - 1, n - 1);
                    end
                end
            end
        end

        function solve(s, loglevel, refineGrid)
            % Solve the problem.
            %
            % :parameter s:
            %    Instance of class 'Stack'.
            % :parameter loglevel:
            %    Integer flag controlling the amount of diagnostic output.
            %    Zero supresses all output, and 5 produces very verbose
            %    output.
            % :parameter refine_grid:
            %    Integer, 1 to allow grid refinement, 0 to disallow.

            calllib(ct, 'sim1D_solve', s.stID, loglevel, refineGrid);
        end

        function writeStats(s)
            % Print statistics for the current solution.
            % Prints a summary of the number of function and Jacobian
            % evaluations for each grid, and the CPU time spent on each
            % one.

            calllib(ct, 'sim1D_writeStats', s.stID, 1);
        end

    end
end
