#!/usr/bin/perl

  my $font = "/usr/local/git/fpa/other/StayPuft.ttf";

   use GD::SecurityImage;

   my $image = GD::SecurityImage->new(
      width      => 200,
      height     => 70,
      ptsize     => 30,
      lines      => 40,
      thickness  => 1,
      send_ctobg => 1,
      font       => $font,
      ptsize     => 36
);
      $image->random('Doug01');
      $image->create(ttf => 'rect', '#FF0000', '#FFFFFF');
      $image->particle(2000);
   my($image_data, $mime_type, $random_number) = $image->out;
print $image_data;
exit;

