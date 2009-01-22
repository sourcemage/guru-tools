#!/usr/bin/perl
$\="\n";

$nw="New Spells";
$mv="Moved Spells";
$vb="Version Bumped Spells";
$bf="Bugfixed Spells";
$dl="Deleted Spells";

@order=($nw,$vb,$bf,$dl,$mv);

sub read_image{
  my ($filename)=@_;
  my %hash1;
  open FILE,"<$filename" or die "$! cannot open $filename";
  while(<FILE>){
    chomp;
    ($section,$spell,$version,$md5)=split /:/;
    $hash1{$spell}=[$section,$version,$md5];
    #hash1: spells -> (section version md5)
  }
  close FILE;
  return \%hash1;
}


sub report_common{
  my($hashref,$foo,$bar)=@_;
  @baz=sort keys %{$$hashref{$foo}{$bar}};
  if(@baz>0){
    print "  $bar";
    map{
      printf "    %-20ls %s\n",$_,$$hashref{$foo}{$bar}{$_};
    }@baz;
    print "";
  }
}

sub report_type{
  my ($hashref)=@_;
  map{
    $foo=$_;
    print "$foo";
    map {
      report_common($hashref,$foo,$_);
    }sort keys %{$$hashref{$foo}};
    print "";
  }@order;
}
sub report_section{
  my ($hashref)=@_;
  map{
    $foo=$_;
    print "$foo";
    map {
      report_common($hashref,$foo,$_);
    }@order;
    print "";
  }sort keys %{$hashref};
}

sub entry1{
  my ($hashref,$section,$type,$spell,$info)=@_;
  $$hashref{$section}{$type}{$spell}=$info;
}
sub entry2{
  my ($hashref,$section,$type,$spell,$info)=@_;
  $$hashref{$type}{$section}{$spell}=$info;
}

#this two functions should meld one i learn fnc pointers
sub sts{
  my($rold,$rnew)=@_;
  my %hashish;
  map{
    ($nsection,$nversion,$nmd5)=@{$$rnew{$_}};
    if(defined $$rold{$_}){
      ($osection,$oversion,$omd5)=@{$$rold{$_}};
      if($oversion ne $nversion){
        &$entry(\%hashish,$nsection,$vb,$_,"$oversion -> $nversion");
      }elsif($omd5 ne $nmd5){
        &$entry(\%hashish,$nsection,$bf,$_,"$nversion");
      }
      if($osection ne $nsection){
        &$entry(\%hashish,$osection,$mv,$_,"$osection -> $nsection");
      }
    }else{
      &$entry(\%hashish,$nsection,$nw,$_,"$nversion");
    }
  }keys %$rnew;
  map{
    ($osection,$oversion,$omd5)=@{$$rold{$_}};
    if (! defined $$rnew{$_}) {
      &$entry(\%hashish,$osection,$dl,$_,"$oversion");
    }
  }keys %$rold;
  return \%hashish;
}

$old=read_image $ARGV[0];
$new=read_image $ARGV[1];

$entry=\&entry1;
$href=sts($old,$new);
report_section $href;

print "--------------------------------------------------\n";

$entry=\&entry2;
$href=sts($old,$new);
report_type $href;

