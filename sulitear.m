%   Original author: En Yi
%   A solitaire game on MATLAB, very self-explanatory
%   Not optimised though
%   Have fun!
%   Anyone can modify it, just need to give credits to the original author
%   Future considerations:
%   -Add dragging functions
%   -Add card animations
%   -Find a better way to render the game for better resolution
%   -Allow deck customisation?
function sulitear()
clc;
% Get information about the screen
scrsz = get(0,'ScreenSize');
win_ratio = scrsz(3:4)/scrsz(3);
win_size = scrsz(3:4)*0.8;
% Construct the window
win = figure('ToolBar','none','Name','Solitaire',...
    'NumberTitle','off','MenuBar','none',...
    'Resize','off','Visible','off','Color',[0 0 0]/255,...
    'Position',[scrsz(3:4)-win_size*1.05 win_size],...
    'ButtonDownFcn',@check_clicked_deck,...
    'KeyPressFcn',@restart);

% Prepare a variable to indicate which deck are selected
previous_selected_deck = 0;
win_game = 0;
% Prepare cards and the playing field
playing_cards = prepare_playing_cards();
[playing_decks,draw_deck,discard_deck,goal_decks,playfield_size] = prepare_playfield(playing_cards,win_ratio);
% Prepare the drawing axes
disp_axes = axes('Parent',win,'Position',[0 0 1 1]);
set(disp_axes,'Xlim',[0 playfield_size(1)],'Ylim',[0 playfield_size(2)],...
    'XLimMode','manual','YLimMode','manual','Visible','off','NextPlot','add');

% Prepare winning text

% Draw the playing field  on the axes
draw_playfield();

% Prepare the text and hide it
win_text = text(disp_axes,playfield_size(1)/2,playfield_size(2)/4,'You Won! Press R to Try Again!',...
                        'PickableParts','none','Color',[1 1 1],'FontSize',15,'Visible','off',...
                        'HorizontalAlignment','center');
load_text = text(disp_axes,playfield_size(1),playfield_size(2)/8,'Loading...',...
                        'PickableParts','none','Color',[1 1 1],'FontSize',15,'Visible','off',...
                        'HorizontalAlignment','right');
                    
set(win,'Visible','on')

%% Callback functions
%%% Idea: can optimise by splitting the window into regions and check only
%%% the decks in that region
    function check_clicked_deck(~,~)
        % Only allow left clicks, subject to changes
        if ~strcmp(get(win,'selectiontype'),{'normal','open'})
            return
        end
        [Xx,Yy] = get_mouse_pos();
        if draw_deck.check_Deck_Collision(Xx,Yy,'first')
            reset_card_selection();
            % Check for the draw pile collision
            if draw_deck.get_Number_Of_Cards() + discard_deck.get_Number_Of_Cards()>0           % If not all cards are taken away
                if draw_deck.get_Number_Of_Cards()>0                                            % If there's cards to be drawn
                    previous_selected_deck = draw_deck;
                    draw_deck.selected_start_index = min(draw_deck.get_Number_Of_Cards(),3);
                    discard_deck.set_Current_Display(draw_deck.selected_start_index);           % Set the discard to show that amount of cards transferred
                    draw_deck.transfer_Selected_Cards(discard_deck,'flip');                     % Transfer cards to discard pile, up to 3
                    reset_card_selection();
                else
                    previous_selected_deck = discard_deck;                                           % Transfer back the cards from discard pile
                    discard_deck.selected_start_index = discard_deck.get_Number_Of_Cards();
                    discard_deck.transfer_Selected_Cards(draw_deck,'flip');
                    reset_card_selection();
                end
                draw_deck.update_Deck_Graphics(disp_axes);
                discard_deck.update_Deck_Graphics(disp_axes);
            end
            return
        end
        
        % Check for the draw pile collision
        if discard_deck.check_Deck_Collision(Xx,Yy,'first')
            if previous_selected_deck == discard_deck
                reset_card_selection();
                return
            end
            reset_card_selection();
            if discard_deck.get_Number_Of_Cards() > 0
                discard_deck.selected_start_index = 1;                      % Only allow selection, up to one card
                previous_selected_deck = discard_deck;
                discard_deck.update_Deck_Graphics(disp_axes);
            end
            return
        end
        
        % Check for the playing deck
        for i = 1:length(playing_decks)
            if playing_decks(i).check_Deck_Collision(Xx,Yy,'full')
                selected_deck = playing_decks(i);
                s_index = selected_deck.check_selection(Xx,Yy);             %Check which card is selected
                if s_index>=0
                    
                    % Manually open a hidden card, not used
                    %                 if playing_decks(i).check_Deck_Collision(Xx,Yy,'first') && s_index == -1
                    %                     reset_card_selection();
                    %                     selected_deck.reveal_Hidden_Card(1)
                    %                     selected_deck.update_Deck_Graphics(disp_axes);
                    %                     return
                    %                 end
                    
                    % If a deck is previously selected
                    if (previous_selected_deck ~= 0)
                        if previous_selected_deck ~= selected_deck
                            [transferring_num,transferring_col]= determine_card(get_bottom_selected(previous_selected_deck));
                            [destination_num,destination_col] = determine_card(selected_deck.get_Last_Cards());
                            if (transferring_col ~= destination_col &&...                       % If the colour alternates
                                    transferring_num == destination_num-1)                      % If the number are in sequence
                                transfer_Selected_Cards(previous_selected_deck,selected_deck);
                            end
                            auto_open_hiddencard();                                             % Reveal a hidden card if there is one
                        end
                        reset_card_selection();
                    else
                        if ~selected_deck.is_Empty()
                            reset_card_selection();
                            selected_deck.selected_start_index = s_index;
                            previous_selected_deck = selected_deck;
                        end
                    end
                else
                    reset_card_selection();
                end
                selected_deck.update_Deck_Graphics(disp_axes);
                return
            end
        end
        
        % Check for the goal decks
        for i = 1:length(goal_decks)
            if goal_decks(i).check_Deck_Collision(Xx,Yy,'first')
                selected_deck = goal_decks(i);
                
                if (previous_selected_deck ~= 0)
                    if previous_selected_deck.selected_start_index == 1     % Only allow one card transfer
                        [transferring_num,~,transferring_suit]= ...
                            determine_card(get_bottom_selected(previous_selected_deck));
                        [destination_num,~,destination_suit] = ...
                            determine_card(selected_deck.get_Last_Cards());
                        
                        if (transferring_suit == destination_suit  ...      % If card is same suit
                                && transferring_num == destination_num+1 )...   % Must be consecutive number
                                || transferring_num == 1                        % Or is the ace
                            transfer_Selected_Cards(previous_selected_deck,selected_deck);
                        end
                    end
                    auto_open_hiddencard();
                    reset_card_selection();
                else
                    if ~selected_deck.is_Empty()
                        reset_card_selection();
                        selected_deck.selected_start_index = 1;
                        previous_selected_deck = selected_deck;
                    end
                end
                selected_deck.update_Deck_Graphics(disp_axes);
                
                % Check for winning condition
                total_goal_cards = 0;
                for j = 1:length(goal_decks)
                    total_goal_cards = total_goal_cards+goal_decks(j).get_Number_Of_Cards();
                end
                if total_goal_cards == 52 && win_game == 0
                    win_game = 1;
                    set(win_text,'Visible','on');
                    
                    reset_card_selection();
                end
                
                return
            end
        end
        
        
    end

%% Non-Callback functions
% Prepare the card holders
    function restart(~,evtdata)
        set(load_text,'Visible','on');drawnow;
        % Press R to try again
        if strcmp(evtdata.Key,'r')
            reset_entire_game(playing_cards);
        end
        set(load_text,'Visible','off');
    end
% Prepare the playing field dimension with the card holders
    function [playing_decks,draw_deck,discard_deck,goal_decks,playfield_size] = prepare_playfield(cards,win_ratio)
        card_size = size(cards(1).get_Card_Image('front'));
        card_width = card_size(2);
        card_height = card_size(1);
        offset = round(card_width);
        n = 7;
        border_offset = 10;
        playfield_width = round((card_size(2)+offset)*n-offset+2*border_offset);
%         i = 1;
%         while(playfield_width-card_width*i>=0)
%             i = i+1;
%         end
%         playfield_width = card_width*i;
%         i = 1;
        playfield_size = round([playfield_width playfield_width].*win_ratio);
%         while(playfield_size(2)-card_height*i>=0)
%             i = i+1;
%         end
%         playfield_size(2) = card_height*i;
        
        % Compute the position and dimensions
        start_x = border_offset;
        start_y =playfield_size(2)-card_height-4*border_offset;
        card_offset = (start_y-card_height-offset)/18;
        % Initialise the card holders
        
        draw_deck = cardHolder(start_x,playfield_size(2)-border_offset,...
            [],card_width,card_height,card_offset,'horizontal',1,1,1,0);
        discard_deck = cardHolder(start_x+card_width+offset,playfield_size(2)-border_offset,...
            [],card_width,card_height,card_offset,'horizontal',3,0,0,0);
        
        for i = 4:n
            goal_decks(i-3) = cardHolder(start_x+(card_width+offset)*(i-1),...
                playfield_size(2)-border_offset,[],card_width,card_height,card_offset,'vertical',1,0,0,1);
        end
        % Shuffle the cards
        remaining_cards = cards(randperm(length(cards)));
        
        for i = 1:n
            dealt_cards = remaining_cards(1:i);
            playing_decks(i) = cardHolder(start_x+(card_width+offset)*(i-1),...
                start_y,dealt_cards,card_width,card_height,card_offset,'vertical',-1,i-1,0,1);
            remaining_cards = remaining_cards(i+1:end);
        end
        
        draw_deck.append_Cards(remaining_cards);
    end

% Prepare a deck of cards
    function all_cards = prepare_playing_cards()
        card_values = cumsum(ones(13,4))'+ cumsum(ones(4,13)*100);
        try
            crd = load('card_images.mat');
            card_images = crd.cards;
            card_backimage = crd.card_backimage;
            for i = 1:52
                j = ceil(i/13);
                k = mod(i-1,13)+1;
                all_cards(i) = Cards(card_values(j,k),card_images{j,k},card_backimage);
            end
        catch
            disp('Load failed')
            close all
            % Should maybe have a variable for loading failure
        end
    end
% % Distribute the playing cards, not used
%     function [dealt_cards,remaining_cards] = deal_cards(cards,amount)
%         remaining_cards = cards;
%         for i = 1:amount
%             n_of_cards = length(remaining_cards);
%             index = randi(n_of_cards);
%             dealt_cards(i) = remaining_cards(index);
%             remaining_cards = [remaining_cards(1:index-1) remaining_cards(index+1:end)];
%         end
%     end

% Reset the game
    function reset_entire_game(cards)
        if win_game
            win_game=0;
            set(win_text,'Visible','off');
        end
        remaining_cards = cards(randperm(length(cards)));
        for i = 1:length(playing_decks)
            playing_decks(i).clear_Deck();
            playing_decks(i).append_Cards(remaining_cards(1:i));
            playing_decks(i).hidden_start_index = i-1;
            playing_decks(i).update_Deck_Graphics(disp_axes);
            remaining_cards = remaining_cards(i+1:end);
        end
        
        for i = 1:length(goal_decks)
            goal_decks(i).clear_Deck();
            goal_decks(i).update_Deck_Graphics(disp_axes);
        end
        
        discard_deck.clear_Deck();
        discard_deck.update_Deck_Graphics(disp_axes);
        
        draw_deck.clear_Deck();
        draw_deck.append_Cards(remaining_cards);
        draw_deck.update_Deck_Graphics(disp_axes);
        
        reset_card_selection();
    end

% Reset the card selection to none and updating the deck graphic
    function reset_card_selection()
        if previous_selected_deck ~= 0
            previous_selected_deck.selected_start_index = 0;
            previous_selected_deck.update_Deck_Graphics(disp_axes)
            previous_selected_deck = 0;
        end
    end

% Draw the play field
    function draw_playfield()
        cla(disp_axes);     % Clear the play field axes, not that it is needed since it is only called during initialisation
        for i = 1:length(playing_decks)
            playing_decks(i).render_deck_outline(disp_axes);
            playing_decks(i).update_Deck_Graphics(disp_axes);
        end
        draw_deck.render_deck_outline(disp_axes);
        draw_deck.update_Deck_Graphics(disp_axes);
        %discard_deck.render_deck_outline(disp_axes);
        discard_deck.update_Deck_Graphics(disp_axes);
        
        for i = 1:length(goal_decks)
            goal_decks(i).render_deck_outline(disp_axes);
            goal_decks(i).update_Deck_Graphics(disp_axes);
        end
    end

% Determine the number, colour , and suit of the colours
    function [num,colour,suit] = determine_card(card,varargin)
        if isa(card, 'Cards')
            [num,colour,suit] = card.get_Card_Info();
        else
            if card == 0
                if ~isempty(varargin)
                    num = varargin{1};  % Specify the value an empty deck should take
                else
                    num = 14;           % Allow king to go into empty slots by default
                end
            else
                num = -1;               % The deck is having hidden cards
            end
            suit = -1;
            colour = -1;
        end
    end

% Open hidden cards automatically
    function auto_open_hiddencard()
        if (previous_selected_deck.hidden_start_index >0 ...
                && previous_selected_deck.get_Number_Of_Cards() == previous_selected_deck.hidden_start_index)
            previous_selected_deck.reveal_Hidden_Card(1)
        end
    end

% Get the mouse position
    function[X,Y]= get_mouse_pos()
        mpos = get(disp_axes,'CurrentPoint');
        X = mpos(1,1);
        Y = mpos(1,2);
    end
end