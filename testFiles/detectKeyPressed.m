function detectKeyPressed()
%-----------------------------------------------------------------------
% Script: detectKeyPressed.m
% Author: Justin Frandsen
% Date: 07/20/2023
% Description: Matlab Script that outputs the name of the keyboard
%              key that you pressed
%
% Usage:
% - type function into Command Window
% - Script will output key name into Command Window
%-----------------------------------------------------------------------
    WaitSecs(1);
    KbName('UnifyKeyNames');
    [~, keyCode] = KbWait();
    keyPressed = KbName(keyCode);
    disp(['Key pressed: ', keyPressed]);
end
