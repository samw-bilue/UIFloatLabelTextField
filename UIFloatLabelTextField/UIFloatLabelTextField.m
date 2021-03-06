//
//  UIFloatLabelTextField.m
//  UIFloatLabelTextField
//
//  Created by Arthur Sabintsev on 3/3/14.
//  Copyright (c) 2014 Arthur Ariel Sabintsev. All rights reserved.
//

#import "UIFloatLabelTextField.h"

@interface UIFloatLabelTextField ()

@property (nonatomic, copy) NSString *storedText;
@property (nonatomic, strong) UIButton *clearTextFieldButton;
@property (nonatomic, assign) CGFloat xOrigin;
@property (nonatomic, assign) CGFloat horizontalPadding;
@property (nonatomic, assign) CGFloat verticalPadding;
@property NSDictionary *placeholderAttributes;

@end

@implementation UIFloatLabelTextField

#pragma mark - Initialization
- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    
    return self;
}

#pragma mark - Breakdown
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:nil];
}

#pragma mark - Setup
- (void)setup
{
    // Build textField
    [self setupTextField];
    
    // Reference Apple's clearButton and add animation
    //[self setupClearTextFieldButton];
    
    [self setupFloatLabel];
    
    // Enable default UIMenuController options
    [self setupMenuController];
}

- (void)setupTextField
{
    // Textfield Padding
    _horizontalPadding = 5.0f;
    _verticalPadding = 0.5f * CGRectGetHeight([self frame]);
    
    // Text Alignment
    [self setTextAlignment:NSTextAlignmentLeft];
    
    // Enable clearButton when textField becomes firstResponder
    self.clearButtonMode = UITextFieldViewModeWhileEditing;

    /*
     Observer for replicating `textField:shouldChangeCharactersInRange:replacementString:` UITextFieldDelegate method,
     without explicitly using UITextFieldDelegate.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)setupClearTextFieldButton
{
    // Create selector for Apple's built-in UITextField button - clearButton
    SEL clearButtonSelector = NSSelectorFromString(@"clearButton");
    
    // Reference clearButton getter
    IMP clearButtonImplementation = [self methodForSelector:clearButtonSelector];
    
    // Create function pointer that returns UIButton from implementation of method that contains clearButtonSelector
    UIButton * (* clearButtonFunctionPointer)(id, SEL) = (UIButton *(*)(id, SEL))clearButtonImplementation;
	
    // Set clearTextFieldButton reference to "clearButton" from clearButtonSelector
    _clearTextFieldButton = clearButtonFunctionPointer(self, clearButtonSelector);
    
    // Remove all clearTextFieldButton target-actions (e.g., Apple's standard clearButton actions)
    [self.clearTextFieldButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    
    // Add new target-action for clearTextFieldButton
    [_clearTextFieldButton addTarget:self action:@selector(clearTextField) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupFloatLabel
{
	// colors
	//_floatLabelPassiveColor = [UIColor lightGrayColor];
	_floatLabelActiveColor = [UIColor blueColor];
	
	// floatLabel
	_floatLabel = [UILabel new];
    _floatLabel.textColor = self.textColor;
    _floatLabel.font =[UIFont boldSystemFontOfSize:12.0f];
    _floatLabel.alpha = 0.0f;
    [_floatLabel setCenter:CGPointMake(_xOrigin, _verticalPadding)];
	[self addSubview:_floatLabel];
	
    
    // animationDuration
    _floatLabelAnimationDuration = @0.25;
}

- (void)setupMenuController
{
    _pastingEnabled = @YES;
    _copyingEnabled = @YES;
    _cuttingEnabled = @YES;
    _selectEnabled = @YES;
    _selectAllEnabled = @YES;
}

#pragma mark - Animation
- (void)toggleFloatLabel:(UIFloatLabelAnimationType)animationType
{
    // Placeholder
    self.placeholder = (animationType == UIFloatLabelAnimationTypeShow) ? @"" : [_floatLabel text];
    
    // Reference textAlignment to reset origin of textField and floatLabel
    _floatLabel.textAlignment = self.textAlignment = [self textAlignment];
    
    // Common animation parameters
    UIViewAnimationOptions easingOptions = (animationType == UIFloatLabelAnimationTypeShow) ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn;
    UIViewAnimationOptions combinedOptions = UIViewAnimationOptionBeginFromCurrentState | easingOptions;
    void (^animationBlock)(void) = ^{
        [self setDynamicViewProperties:animationType];
    };
    
    // Toggle floatLabel visibility via UIView animation
    [UIView animateWithDuration:[_floatLabelAnimationDuration floatValue]
                          delay:0.0f
                        options:combinedOptions
                     animations:animationBlock
                     completion:nil];
}

- (void)animateClearingTextFieldWithArray:(NSTimer *)timer
{
    // Reference textArray from NSTimer object
    NSMutableArray *textArray = [timer userInfo];
    
    /*
     Remove last letter (e.g., last object in array) per method call,
     and display updated/truncated textField text.
     */
    if ([textArray count]) {
        if ([textArray count] == 1) {
            [self toggleFloatLabel:UIFloatLabelAnimationTypeHide];
        }
        [textArray removeLastObject];
        NSString *csvString = [textArray componentsJoinedByString:@","];
        _storedText = [csvString stringByReplacingOccurrencesOfString:@"," withString:@""];
        self.text = _storedText;
    } else {
        _storedText = nil;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        [timer invalidate];
        [self toggleFloatLabel:UIFloatLabelAnimationTypeHide];
        [self resignFirstResponder];
    }
}

#pragma mark - Helpers
- (UIEdgeInsets)floatLabelInsets
{
    return UIEdgeInsetsMake(_floatLabel.font.lineHeight,
                            _horizontalPadding,
                            0.0f,
                            _horizontalPadding);
}

- (UIEdgeInsets)editingFloatLabelInsets
{
	return UIEdgeInsetsMake(_floatLabel.font.lineHeight + (_horizontalPadding / 2),
							_horizontalPadding,
							0.0f,
							_horizontalPadding);
}

- (void)textDidChange:(NSNotification *)notification
{
    assert([notification.name isEqualToString:UITextFieldTextDidChangeNotification]);
    
    if (notification.object == self) {
        if (([self.text length] > 0) != (_storedText.length > 0)) {
            if ([self.text length] > 0) {
                if (![_floatLabel alpha]) {
                    [self toggleFloatLabel:UIFloatLabelAnimationTypeShow];
                }
            } else {
                if ([_floatLabel alpha]) {
                    [self toggleFloatLabel:UIFloatLabelAnimationTypeHide];
                }
            }
        }
        _storedText = self.text;
    }
}

- (void)clearTextField
{
    // Create array, where each index contains one character from textField
    NSMutableArray *textArray = [@[] mutableCopy];
    NSUInteger i = 0;
    while (i < [_storedText length]) {
        NSString *character = [_storedText substringWithRange:NSMakeRange(i, 1)];
        [textArray addObject:character];
        ++i;
    }
    
    // Reset text before animation
    self.text = _storedText;
    
    // Calculate duraiton based on _floatLabelAnimationDuration and number letters in textField
    CGFloat duration = [_floatLabelAnimationDuration floatValue] / [textArray count];
    
    // Perform animation
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(animateClearingTextFieldWithArray:) userInfo:textArray repeats:YES];
}

- (void)setDynamicViewProperties:(UIFloatLabelAnimationType)animationType
{
    _floatLabel.alpha = (animationType == UIFloatLabelAnimationTypeShow) ? 1.0f : 0.0f;
    CGFloat yOrigin = (animationType == UIFloatLabelAnimationTypeShow) ? 3.0f : _verticalPadding;
    _floatLabel.frame = CGRectMake(_xOrigin,
                                   yOrigin,
                                   CGRectGetWidth([_floatLabel frame]),
                                   CGRectGetHeight([_floatLabel frame]));
}

- (void)updateRectForTextFieldGeneratedViaAutoLayout
{
    _verticalPadding = 0.5f * CGRectGetHeight([self frame]);
    
    // Do not shift the frame if textField is pre-populated
    if (![self.text length]) {
        _floatLabel.frame = CGRectMake(_xOrigin,
                                       _verticalPadding,
                                       CGRectGetWidth([_floatLabel frame]),
                                       CGRectGetHeight([_floatLabel frame]));
    }
}

#pragma mark - Properties

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    if (!_placeholderFont)
            _placeholderFont = [UIFont systemFontOfSize:12.0f];
    
    [self setPlaceholder:self.placeholder];
}

- (void)setPlaceholderFont:(UIFont *)placeholderFont
{
    _placeholderFont = placeholderFont;
    if (!_placeholderColor)
        _placeholderColor = [UIColor grayColor];
    
    [self setPlaceholder:self.placeholder];
}

#pragma mark - UITextField (Override)
- (void)setText:(NSString *)text
{
    [super setText:text];
    
    // When textField is pre-populated, show non-animated version of floatLabel
    if ([text length] && !_storedText) {
        [self setDynamicViewProperties:UIFloatLabelAnimationTypeShow];
		_floatLabel.textColor = self.textColor;
    }
}

- (void)setPlaceholder:(NSString *)placeholder
{
    if (self.placeholderColor && self.placeholderFont) {
        self.placeholderAttributes = @{ NSForegroundColorAttributeName : self.placeholderColor,
                                        NSFontAttributeName : self.placeholderFont };
    }
    
    [super setPlaceholder:placeholder];
    [self applyPlaceholderText:placeholder];
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    if ([super respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        [super setAttributedPlaceholder:attributedPlaceholder];
        self.placeholderAttributes = [attributedPlaceholder attributesAtIndex:0 effectiveRange:0];
        [self applyPlaceholderText:attributedPlaceholder.string];
    }
    else {
        NSLog(@"This version of iOS does not support [UITextField setAttributedPlaceholder]");
        [self doesNotRecognizeSelector:_cmd];
    }
}

- (void)applyPlaceholderText:(NSString *)placeholderText
{
    if ([placeholderText length]) {
        _floatLabel.text = placeholderText;
    }
    
    [_floatLabel sizeToFit];
}

- (void)drawPlaceholderInRect:(CGRect)rect
{
    //if we have attributes and we're able to draw with them, do so, otherwise defer to the default iOS implementation
    if (self.placeholderAttributes && [self.placeholder respondsToSelector:@selector(drawInRect:withAttributes:)]) {
        [self.placeholder drawInRect:rect withAttributes:self.placeholderAttributes];
    }
    else {
        [super drawPlaceholderInRect:rect];
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    
    switch (textAlignment) {
        case NSTextAlignmentRight: {
            _xOrigin = CGRectGetWidth([self frame]) - CGRectGetWidth([_floatLabel frame]) - _horizontalPadding;
        } break;
            
        case NSTextAlignmentCenter: {
            _xOrigin = CGRectGetWidth([self frame])/2.0f - CGRectGetWidth([_floatLabel frame])/2.0f;
        } break;
            
        default: // NSTextAlignmentLeft, NSTextAlignmentJustified, NSTextAlignmentNatural
            _xOrigin = _horizontalPadding;
            break;
    }
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect([super textRectForBounds:bounds], [self floatLabelInsets]);
}

- (CGRect)editingRectForBounds:(CGRect)bounds;
{
	return UIEdgeInsetsInsetRect([super editingRectForBounds:bounds], [self editingFloatLabelInsets]);
}

/*
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return UIEdgeInsetsInsetRect([super editingRectForBounds:bounds], [self floatLabelInsets]);
}
*/

#pragma mark - UILabel (Override)
- (void)setFloatLabelFont:(UIFont *)floatLabelFont
{
    _floatLabelFont = floatLabelFont;
    _floatLabel.font = _floatLabelFont;
}

#pragma mark - UIView (Override)
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setTextAlignment:[self textAlignment]];
    
    if ([self.text length])
        [self setDynamicViewProperties:UIFloatLabelAnimationTypeShow];
    else
        [self setDynamicViewProperties:UIFloatLabelAnimationTypeHide];
}

#pragma mark - UIResponder (Override)
-(BOOL)becomeFirstResponder
{
    [super becomeFirstResponder];
	
    /*
     verticalPadding must be manually set if textField was initialized
     using NSAutoLayout constraints
     */
    if (!_verticalPadding) {
        [self updateRectForTextFieldGeneratedViaAutoLayout];
    }
    
    _floatLabel.textColor = _floatLabelActiveColor;
    _storedText = [self text];
	
    return YES;
}

- (BOOL)resignFirstResponder
{
    if ([_floatLabel.text length]) {
        _floatLabel.textColor = _floatLabelPassiveColor;
    }
    
    [super resignFirstResponder];
    
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:)) { // Toggle Pasting
        return ([_pastingEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(copy:)) { // Toggle Copying
        return ([_copyingEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(cut:)) { // Toggle Cutting
        return ([_cuttingEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(select:)) { // Toggle Select
        return ([_selectEnabled boolValue]) ? YES : NO;
    } else if (action == @selector(selectAll:)) { // Toggle Select All
        return ([_selectAllEnabled boolValue]) ? YES : NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

@end
