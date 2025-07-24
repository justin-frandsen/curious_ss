%-------------------------------------------------------------------------
% Script: randomizorImproved.m
% Author: Justin Frandsen
% Date: 07/15/2025 format: DD/MM/YYYY
% Description: Improved version of the randomizor used on the first scene 
%     search experiment. creates conditions for the multiscene experiment.
%
% Usage:
% - fileDirectory: Set total subs, run, and trials, and it will randomize 
%   the order of presentation of the various scenes and trial variables.
% - Script will output a struct containing this information.
%-------------------------------------------------------------------------

% Restoring default RNG settings
rng('shuffle');

% Initialize the main struct to hold 500 sub-structs (subjects)
randomizor_matrix = struct();

total_subs = 500;

% Number of runs
number_of_test_runs = 6;
total_runs = number_of_test_runs + 1;

% Number of trials
number_trials = 72;

% get all kitchen scenes in the kitchen dir
all_main_scenes = dir('stimuli/scenes/main_scenes/*');
all_scenes = all_scenes(~ismember({all_scenes.name},{'.','..','.DS_Store'}));

% get all shapes in the shape dir
all_shapes = dir('Stimuli/shapes/transparent_black/*');
all_shapes = all_shapes(~ismember({all_shapes.name},{'.','..', '.DS_Store'}));

target_inds = [1 2 3 4]; % Indices of target shapes
run_randomizor = 2:total_runs;

scene_randomizor = zeros(length(scene_type_inds) * length(bathroom_scenes_inds) * length(target_inds), 3);

row_index = 1;
for scene_type = 1:length(scene_type_inds)
    for bathroom_scene = 1:length(bathroom_scenes_inds)
        for target_num = 1:length(target_inds)
            scene_randomizor(row_index, :) = [scene_type bathroom_scene target_num];
            row_index = row_index + 1;
        end
    end
end

practice_scene_randomizor = zeros(length(scene_type_inds) * length(practice_bathroom_scenes_inds), 5);

target_num = 1; % Reset target number to 1 to start cycling through targets
position_type = 0; %0 is valid, 1 is 1st invalid position 1, 2 is 2nd invalid position
counter = 0; % Counter to cycle through targets and reset after every 3 iterations
for scene_type = 1:length(scene_type_inds)
    %create a var scene_randomizor that contains all scenes in all conditions (this is later suffled for each participant)
    for bathroom_scene = 1:length(practice_bathroom_scenes_inds)
        if scene_type == 1
            % Reset position_type to 0 to cycle through valid and invalid positions.
            % Position types: 0 is valid, 1 is the first invalid position, 2 is the second invalid position.
            position_type = 0;
        end

        this_row = [scene_type bathroom_scene target_num position_type 1];
        practice_scene_randomizor((scene_type-1)*length(practice_bathroom_scenes_inds) + bathroom_scene, :) = this_row;

        counter = counter + 1;

        if counter == 3
            target_num = target_num + 1; % Increment target number after every 3 iterations
            counter = 0;
        end

        position_type = position_type + 1;

        % Reset target number to 1 if it exceeds 3 to ensure that the target number cycles through 1 to 3.
        % This is necessary because there are only 3 targets, and we need to repeatedly assign these targets
        % to different scenes in a cyclic manner.
        if target_num > 3
            target_num = 1;
        end

        if position_type > 2
            position_type = 0;
        end
    end
end

%col 1 is scene type 1:3
%Col 2 is index into that scene type
%Col 3 is target ind
%Col 4 condition 1 is invalid 0 is valid
%Col 5 is run number

%change it so that 0 is associated location 
kitchen_condition_chooser = [1 2 0 0 0 0 0 0];
bathroom_condition_chooser = [0 1 2];

%this chooses which direction each of the three positions (wall, counter, floor) will be oriented
t_direction_matrix = [
    0, 0, 1;
    0, 1, 0;
    1, 1, 0;
    1, 0, 1;];

practice_t_direction_matrix = [
    0, 0, 1;
    0, 1, 0;
    1, 1, 0;
    1, 0, 1;
    0, 1, 1;
    1, 0, 0;];

%calculates the number of times we have to repeate the t_direction_matrix for the total trials
number_of_reps = number_trials/length(t_direction_matrix);

% get t_direction matrix for practice run
practice_number_of_reps = 18/length(practice_t_direction_matrix);

%repeats the t_direction_matrix for the number of trials
main_t_direction_matrix = repmat(t_direction_matrix, ceil(number_of_reps), 1);

%repeats the t_direction_matrix for the number of trials
practice_t_direction_matrix = repmat(practice_t_direction_matrix, practice_number_of_reps, 1);

%loops through all subjects
for subject = 1:total_subs
    if mod(subject, 2) == 0
        scene_type_primary = 'b';
        scene_type_secondary = 'k';
    else
        scene_type_primary = 'k';
        scene_type_secondary = 'b';
    end


    total_count = 0;

    %creates a struct name for this subject
    subStructName = sprintf('subj%d', subject);
    
    % Create the subject struct
    subjectStruct = struct();
    
    %these lines find the index for the target and distractor shapes
    this_subj_target_inds = randsample(1:length(all_shapes), 3); %3 for 3 targets total
    this_subj_distractor_inds = setdiff(1:length(all_shapes), this_subj_target_inds);

    % Generate the first row with a random permutation of 1 to nCols
    target_associations = randperm(3);
    
    %sort scene_randomizor based on col 3 (%Col 3 is target ind)
    scene_randomizor_filtered = scene_randomizor(scene_randomizor(:, 1) == 1, :);
    scene_randomizor_sorted = sortrows(scene_randomizor_filtered, 3);
    % Sort scene_randomizor based on col 3 for scene type 2
    scene_randomizor_filtered_2 = scene_randomizor(scene_randomizor(:, 1) == 2, :);
    scene_randomizor_sorted_2 = sortrows(scene_randomizor_filtered_2, 3);
    
    %goes through the scene_randomizor_sorted matrix and adds a random permutation of the kitchen_condition_chooser matrix
    %this matrix because it is sorted by target this means that each target will have 1/4 of trials be
    %invalid for each target
    matrix_row_counter = 1;
    for number_reps = 1:length(scene_randomizor_sorted)/length(kitchen_condition_chooser)
        scene_randomizor_sorted(matrix_row_counter:matrix_row_counter+length(kitchen_condition_chooser)-1, 4) = kitchen_condition_chooser(randperm(length(kitchen_condition_chooser)));
        matrix_row_counter = matrix_row_counter + length(kitchen_condition_chooser);
    end
    
    %now sort based on the first 2 columns (col 1 is scene type 1:3) (Col 2 is index into that scene type)
    scene_randomizor_sorted = sortrows(scene_randomizor_sorted, 2);
    
    %this does the same as the previous loop but instead is randomizing what run these scenes occur in (this stops the same image from being in the same run)
    matrix_row_counter = 1;
    for number_reps = 1:length(scene_randomizor_sorted)/number_of_test_runs
        scene_randomizor_sorted(matrix_row_counter:matrix_row_counter+5, 5) = run_randomizor(randperm(number_of_test_runs));
        matrix_row_counter = matrix_row_counter + number_of_test_runs;
    end
    
    %x2
    matrix_row_counter = 1;
    for number_reps = 1:length(scene_randomizor_sorted_2)/length(bathroom_condition_chooser)
        scene_randomizor_sorted_2(matrix_row_counter:matrix_row_counter+length(bathroom_condition_chooser)-1, 4) = bathroom_condition_chooser(randperm(length(bathroom_condition_chooser)));
        matrix_row_counter = matrix_row_counter + length(bathroom_condition_chooser);
    end
    
    %now sort based on the first 2 columns (col 1 is scene type 1:3) (Col 2 is index into that scene type)
    scene_randomizor_sorted_2 = sortrows(scene_randomizor_sorted_2, 2);
    
    %this does the same as the previous loop but instead is randomizing what run these scenes occur in (this stops the same image from being in the same run)
    matrix_row_counter = 1;
    for number_reps = 1:length(scene_randomizor_sorted_2)/number_of_test_runs
        scene_randomizor_sorted_2(matrix_row_counter:matrix_row_counter+5, 5) = run_randomizor(randperm(number_of_test_runs));
        matrix_row_counter = matrix_row_counter + number_of_test_runs;
    end
    % Concatenate scene_randomizor_sorted and scene_randomizor_sorted_2
    scene_randomizor_sorted = [scene_randomizor_sorted; scene_randomizor_sorted_2];

    %loop for each run
    for run = 1:total_runs
        tic
        disp([subject run])
        
        %get run struct name
        runStructName = sprintf('run%d', run);

        %create run struct
        runStruct = struct();
        
        if run == 1
            t_direction_matrix = practice_t_direction_matrix;

            %create matrix that holds pairs of distractor indicies and then suffle them
            pairs = nchoosek(1:length(this_subj_distractor_inds), 2);
            pairs_double = vertcat(pairs, pairs(:, [2 1])); %this makes sure each one is equally possible on each side
            shuffled_pairs = pairs_double(randperm(size(pairs_double, 1)), :);

            % Select the first 19 pairs from the shuffled list
            shuffled_pairs = shuffled_pairs(1:number_trials, :);

            %replace the pair value by using it to index into this_subj_distractor_inds
            shuffled_distractor_inds = this_subj_distractor_inds(shuffled_pairs);

            %this keeps shuffeling until there is not too much repitition
            while true
                t_direction_matrix_mixed = t_direction_matrix(randperm(length(t_direction_matrix)), :);

                if ~any(diff(t_direction_matrix_mixed(:, 1)) > 1)
                    break;
                end
            end

            %if not mixed enough it just keeps remixing until it is remixed to the correct format
            while true
                this_run_randomizor_mixed = practice_scene_randomizor(randperm(length(practice_scene_randomizor)), :);
                
                if ~any(diff(this_run_randomizor_mixed(:, 1)) > 2)
                    break;
                end
            end

            this_run_trial_type = strings(length(this_run_randomizor_mixed), 1);

            for row = 1:length(this_run_randomizor_mixed)
                if this_run_randomizor_mixed(row, 1) == 1
                    this_run_trial_type(row) = scene_type_primary;
                else
                    this_run_trial_type(row) = scene_type_secondary;
                end
            end

        else
            t_direction_matrix = main_t_direction_matrix;

            %create matrix that holds pairs of distractor indicies and then suffle them
            pairs = nchoosek(1:length(this_subj_distractor_inds), 2);
            pairs_double = vertcat(pairs, pairs(:, [2 1])); %this makes sure each one is equally possible on each side
            shuffled_pairs = pairs_double(randperm(size(pairs_double, 1)), :);

            % Select the first 19 pairs from the shuffled list
            shuffled_pairs = shuffled_pairs(1:number_trials, :);

            %replace the pair value by using it to index into this_subj_distractor_inds
            shuffled_distractor_inds = this_subj_distractor_inds(shuffled_pairs);

            %this keeps shuffeling until there is not too much repitition
            while true
                t_direction_matrix_mixed = t_direction_matrix(randperm(length(t_direction_matrix)), :);

                if ~any(diff(t_direction_matrix_mixed(:, 1)) > 1)
                    break;
                end
            end

            %find rows that == run
            this_run_rows = scene_randomizor_sorted(:, 5) == run;
            % Extract rows where the 6th column equals 1
            this_run_randomizor = scene_randomizor_sorted(this_run_rows, :);

            %if not mixed enough it just keeps remixing until it is remixed to the correct format
            while true
                this_run_randomizor_mixed = this_run_randomizor(randperm(length(this_run_randomizor)), :);

                if ~any(diff(this_run_randomizor_mixed(:, 1)) > 1) && ~any(diff(this_run_randomizor_mixed(:, 3)) > 2)
                    break;
                end
            end

            this_run_trial_type = strings(length(this_run_randomizor_mixed), 1);

            for row = 1:length(this_run_randomizor_mixed)
                if this_run_randomizor_mixed(row, 1) == 1
                    this_run_trial_type(row) = scene_type_primary;
                else
                    this_run_trial_type(row) = scene_type_secondary;
                end
            end

            %im struggling to remember what this is. I think its counting number of instances of location type in a given run
            %column_index = 1;
            %number_to_count = 3;
            %instances_count = sum(this_run_randomizor_mixed(:, column_index) == number_to_count);
            %total_count = total_count + instances_count;
            %fprintf('Number of instances of %d in column %d: %d\nTotal: %d\n', number_to_count, column_index, instances_count, total_count);
        end
            
        %add variables to save out
        runStruct.('this_run_randomizor') = this_run_randomizor_mixed; %%
        runStruct.('t_direction_matrix_mixed') = t_direction_matrix_mixed; %%
        runStruct.('this_subj_target_inds') = this_subj_target_inds;
        runStruct.('target_associations') = target_associations;
        runStruct.('shuffled_distractor_inds') = shuffled_distractor_inds;
        runStruct.('this_run_trial_type') = this_run_trial_type;

        % Add the run struct to the subject struct and apply runStructName
        subjectStruct.(runStructName) = runStruct;

        toc
    end
    % Add the subject struct to the main struct and apply subStructName
    randomizor_matrix.(subStructName) = subjectStruct;
end

% save trialDataFiles/randomizor.mat randomizor_matrix

%end