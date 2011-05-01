#!/usr/bin/perl
use PDF::API2;

$pdf = PDF::API2->new;
$page = $pdf->page();
$page->mediabox('400,200');
$g = $page->gfx();
$g->strokecolor("#FF0000");
$g->fillcolor("#ffffff");

$g->circle(70,70,20);

$text = $page->text();
$text->translate(20,20);
$font = $pdf->corefont('Helvetica',1);
$text->font($font,24);
$text->text("Hello World");
print $pdf->stringify();
$pdf->end;


exit;
