function counterBalancedData = counterBalancer(var, numTrials)
if mod(numTrials, 12) == 0
    counterBalancedData = zeros(size(var));
    startIndex = 1;
    endIndex = length(var);
    numberOfRepititions = ceil(numTrials/length(var));
    for i = 1:numberOfRepititions
        varToSave = var(randperm(length(var)));
        if endIndex <= numTrials
            counterBalancedData(startIndex:endIndex) = varToSave;
            startIndex = startIndex + length(var);
            endIndex = endIndex + length(var);
        else
            endIndex = numTrials;
            varIndex = endIndex-startIndex+1;
            counterBalancedData(startIndex:endIndex) = varToSave(1:varIndex);
        end
    end
else
    error('Input for numTrials must be divisiable by 12!')
end
end