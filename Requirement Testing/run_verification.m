% Step 1: Load or create requirement set
reqSetFile = "AircraftRequirements.slreqx";

if exist(reqSetFile, 'file')
    reqSet = slreq.load(reqSetFile);  % Load existing requirement set
else
    reqSet = slreq.new(reqSetFile);   % Create new requirement set
    fprintf("Created new requirement set: %s\n", reqSetFile);
end

% Step 2: Add requirements if they don't exist
reqIDs = {"REQ-001", "REQ-002"};
summaries = {"Span under 20 m", "Stable in 25 kt crosswind"};

for k = 1:numel(reqIDs)
    r = find(reqSet, "ID", reqIDs{k});
    if isempty(r)
        add(reqSet, "id", reqIDs{k}, "summary", summaries{k});
        fprintf("Added requirement: %s\n", reqIDs{k});
    end
end

% Step 3: Link each requirement to a MATLAB test function
testFiles = {@test_span, @test_crosswind};

for k = 1:numel(reqIDs)
    req = find(reqSet, "ID", reqIDs{k});
    testFcn = func2str(testFiles{k});
    testPath = which(testFcn);  % Get full path to MATLAB file

    % Check existing links
    links = req.outLinks;
    found = false;
    for L = links
        destInfo = L.destination;  % destination is a struct
        if isfield(destInfo, 'Artifact') && strcmp(destInfo.Artifact, testPath)
            found = true;
            break;
        end
    end

    % Create link if it doesn't exist
    if ~found
        slreq.createLink(req, testPath, 'linkType', 'Test');
        fprintf("Linked %s → %s\n", testFcn, reqIDs{k});
    end
end

% Step 4: Save the requirement set
save(reqSet);
fprintf("Requirement set saved: %s\n", reqSetFile);
