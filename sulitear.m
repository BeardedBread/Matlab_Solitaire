function sulitear()
clc;
% Construct the window with the axes
scrsz = get(0,'ScreenSize');
%TODO Find new method to draw the window
%start_dim = min(scrsz(3)/1.5,scrsz(4)/1.5);%Used for rescaling
win_ratio = scrsz(3:4)/scrsz(3);
win_size = scrsz(3:4)*0.8;
win = figure('ToolBar','none','Name','Solitaire',...
    'NumberTitle','off','MenuBar','none',...
    'Resize','off','Visible','off','Color',[0 0 0]/255,...
    'Position',[scrsz(3:4)-win_size*1.05 win_size],...
    'ButtonDownFcn',@check_clicked_deck,...
    'KeyPressFcn',@restart);

%Prepare card decks and the playing field
playing_cards = prepare_playing_cards();
[playing_decks,draw_deck,discard_deck,goal_decks,playfield_size] = prepare_cardHolders(playing_cards,win_ratio);

disp_axes = axes('Parent',win,'Position',[0 0 1 1]);
set(disp_axes,'Xlim',[0 playfield_size(1)],'Ylim',[0 playfield_size(2)],...
    'XLimMode','manual','YLimMode','manual','Visible','off','NextPlot','add');

set(win,'Visible','on')
% Prepare some variable to indicate cards are selected HERE
transferring_deck = 0;
% draw it on the axes
draw_playfield();
%% Callback functions
%%% Idea: can optimise by splitting the window into regions
    function check_clicked_deck(~,~)
        if ~strcmp(get(win,'selectiontype'),'normal')
            return
        end
        [Xx,Yy] = get_mouse_pos();
        if draw_deck.check_Deck_Collision(Xx,Yy,'first')
            reset_card_selection();
            if draw_deck.get_Number_Of_Cards() + discard_deck.get_Number_Of_Cards()>0
                if draw_deck.get_Number_Of_Cards()>0                              % If there's cards
                    transferring_deck = draw_deck;
                    draw_deck.selected_start_index = min(draw_deck.get_Number_Of_Cards(),3);
                    discard_deck.set_Current_Display(draw_deck.selected_start_index);           % Set the discard to show that amount of cards transferred
                    draw_deck.transfer_Selected_Cards(discard_deck,'flip');                     % Transfer cards to discard pile, up to 3
                    reset_card_selection();
                else 
                    transferring_deck = discard_deck;                                           % Transfer back the cards from discard pile
                    discard_deck.selected_start_index = discard_deck.get_Number_Of_Cards();
                    discard_deck.transfer_Selected_Cards(draw_deck,'flip');
                    reset_card_selection();
                end
                draw_deck.update_Deck_Graphics(disp_axes);
                discard_deck.update_Deck_Graphics(disp_axes);
            end
            return
        end
        
        if discard_deck.check_Deck_Collision(Xx,Yy,'first')             % Else check for discard deck
            if transferring_deck == discard_deck
                reset_card_selection();
                return
            end
            reset_card_selection();
            if discard_deck.get_Number_Of_Cards() > 0                   % Only allow selection, up to one card
                discard_deck.selected_start_index = 1;
                transferring_deck = discard_deck;
                discard_deck.update_Deck_Graphics(disp_axes);
            end
            return
        end
        
        for i = 1:length(playing_decks)
            % This part is only for the playing deck
            if playing_decks(i).check_Deck_Collision(Xx,Yy,'full') %Check if any deck is clicked
                selected_deck = playing_decks(i);
                s_index = selected_deck.check_selection(Xx,Yy);      %If so, check which card is selected
                %If no selection was before or more than a card is
                %selected and there are cards remaining in the deck
%                 if playing_decks(i).check_Deck_Collision(Xx,Yy,'first') && s_index == -1
%                     reset_card_selection();
%                     selected_deck.reveal_Hidden_Card(1)
%                     selected_deck.update_Deck_Graphics(disp_axes);
%                     break
%                 end
                
                if (transferring_deck ~= 0)
                    %if s_index>=0
                    if transferring_deck ~= selected_deck % If the selected deck is not the previously selected deck
                        [transferring_num,transferring_col]= determine_card(get_bottom_selected(transferring_deck));
                        [destination_num,destination_col] = determine_card(selected_deck.get_Last_Cards());
                        if (transferring_col ~= destination_col &&... % If the colour alternates
                                transferring_num == destination_num-1) % If the number are in sequence
                            transfer_Selected_Cards(transferring_deck,selected_deck);
                        end
                        % Reveal a hidden card if there is one
                        auto_open_hiddencard();
                    end
                    %end
                    reset_card_selection();
                else
                    % Otherwise move previously selected cards to the currently selected deck
                    if s_index>0
                        %Get the selected cards to be transfered
                        reset_card_selection();
                        selected_deck.selected_start_index = s_index;
                        transferring_deck = selected_deck;
                    end
                end
                selected_deck.update_Deck_Graphics(disp_axes);
                return
            end
        end
        for i = 1:length(goal_decks)
            if goal_decks(i).check_Deck_Collision(Xx,Yy,'first')
                selected_deck = goal_decks(i);
                
                if (transferring_deck ~= 0)
                    if transferring_deck.selected_start_index == 1
                        [transferring_num,~,transferring_suit]= determine_card(get_bottom_selected(transferring_deck));
                        [destination_num,~,destination_suit] = determine_card(selected_deck.get_Last_Cards());
                        if (transferring_suit == destination_suit  && transferring_num == destination_num+1)...
                            || transferring_num == 1
                            transfer_Selected_Cards(transferring_deck,selected_deck);
                        end
                    end
                    auto_open_hiddencard();
                    reset_card_selection();
                else
                    if ~selected_deck.is_Empty()
                        reset_card_selection();
                        selected_deck.selected_start_index = 1;
                        transferring_deck = selected_deck;
                    end
                end
                selected_deck.update_Deck_Graphics(disp_axes);
                
                total_goal_cards = 0;
                for j = 1:length(goal_decks)
                    total_goal_cards = total_goal_cards+goal_decks(j).get_Number_Of_Cards();
                end
                if total_goal_cards == 52
                    uiwait(msgbox('You Won! Press R to Try Again!','YAY!','modal'));
                end
                return
            end
        end
        %%% TODO: check for winning condition
        
    end

%% Non-Callback functions
%Prepare the card holders
    function restart(~,evtdata)
        if strcmp(evtdata.Key,'r')
            reset_entire_game(playing_cards);
        end
    end
    function [playing_decks,draw_deck,discard_deck,goal_decks,playfield_size] = prepare_cardHolders(cards,win_ratio)
        %%% TODO: Automate the draw, discard piles and the goal pile
        card_size = size(cards(1).get_Card_Image('front'));
        card_width = card_size(2);
        card_height = card_size(1);
        offset = round(card_width);
        n = 7;
        border_offset = 10;
        playfield_width = round((card_size(2)+offset)*n-offset+2*border_offset);
        i = 1;
        while(playfield_width-card_width*i>=0)
            i = i+1;
        end
        playfield_width = card_width*i;
        i = 1;
        playfield_size = round([playfield_width playfield_width].*win_ratio);
        while(playfield_size(2)-card_height*i>=0)
            i = i+1;
        end
        playfield_size(2) = card_height*i;
        % Input the number of decks and offset between deck position
        
        % Compute the position and dimensions
        start_x = border_offset;
        start_y =playfield_size(2)-card_height-4*border_offset;
        card_offset = (start_y-card_height-offset)/18;
        % Initialise the card holders
        
        % Manually initialise for testing purposes
        draw_deck = cardHolder(start_x,playfield_size(2)-border_offset,...
            [],card_width,card_height,card_offset,'horizontal',1,1,1,0);
        discard_deck = cardHolder(start_x+card_width+offset,playfield_size(2)-border_offset,...
            [],card_width,card_height,card_offset,'horizontal',3,0,0,0);
        
        for i = 4:n
            goal_decks(i-3) = cardHolder(start_x+(card_width+offset)*(i-1),...
                playfield_size(2)-border_offset,[],card_width,card_height,card_offset,'vertical',1,0,0,1);
        end
        a = randperm(length(cards));
        remaining_cards = cards(a);
        %Loop method, which will be used
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
        end
    end
% Distribute the playing cards
    function [dealt_cards,remaining_cards] = deal_cards(cards,amount)
        remaining_cards = cards;
        for i = 1:amount
            n_of_cards = length(remaining_cards);
            index = randi(n_of_cards);
            dealt_cards(i) = remaining_cards(index);
            remaining_cards = [remaining_cards(1:index-1) remaining_cards(index+1:end)];
        end
    end
    function reset_entire_game(cards)
        a = randperm(length(cards));
        remaining_cards = cards(a);
        for i = 1:length(playing_decks)
            playing_decks(i).clear_Deck();
            dealt_cards= remaining_cards(1:i);
            playing_decks(i).append_Cards(dealt_cards);
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
        if transferring_deck ~= 0
            transferring_deck.selected_start_index = 0;
            transferring_deck.update_Deck_Graphics(disp_axes)
            transferring_deck = 0;
        end
    end

% Draw the play field
    function draw_playfield()
        cla(disp_axes);     % Clear the play field axes
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
                    num = varargin{1};
                else
                    num = 14;
                end
            else
                num = -1;
            end
            suit = -1;
            colour = -1;
        end
    end
    function auto_open_hiddencard()
        if (transferring_deck.hidden_start_index >0 ...
                && transferring_deck.get_Number_Of_Cards() == transferring_deck.hidden_start_index)
            transferring_deck.reveal_Hidden_Card(1)
        end
    end
% Get the mouse position
    function[X,Y]= get_mouse_pos()
        mpos = get(disp_axes,'CurrentPoint');
        X = mpos(1,1);
        Y = mpos(1,2);
    end
end