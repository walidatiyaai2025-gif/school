import 'package:flutter/material.dart';
import '../core/brand.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title,{super.key,this.action});
  final String title;
  final Widget? action;
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.symmetric(vertical:7),
    child:Row(children:[Expanded(child:Text(title,style:const TextStyle(
      color:Brand.navy,fontWeight:FontWeight.w800,fontSize:17))),if(action!=null) action!]));
}

class WhitePanel extends StatelessWidget {
  const WhitePanel({super.key,required this.child,this.padding=const EdgeInsets.all(16)});
  final Widget child;final EdgeInsets padding;
  @override Widget build(BuildContext context)=>Container(
    width:double.infinity,padding:padding,decoration:BoxDecoration(color:Colors.white,
      borderRadius:BorderRadius.circular(20),border:Border.all(color:const Color(0xFFE4ECF7))),
    child:child);
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key,required this.text,this.icon=Icons.info_outline_rounded});
  final String text;final IconData icon;
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(14),decoration:BoxDecoration(
      borderRadius:BorderRadius.circular(16),color:const Color(0xFFE9F2FF)),
    child:Row(children:[Icon(icon,color:Brand.blue),const SizedBox(width:12),
      Expanded(child:Text(text,style:const TextStyle(color:Brand.navy,height:1.5,fontSize:13)))]));
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key,required this.title,required this.icon,required this.onTap,
    this.subtitle,this.trailing});
  final String title;final String? subtitle;final IconData icon;final VoidCallback onTap;
  final Widget? trailing;
  @override Widget build(BuildContext context)=>ListTile(
    onTap:onTap,contentPadding:const EdgeInsets.symmetric(horizontal:6,vertical:2),
    leading:Container(width:42,height:42,decoration:BoxDecoration(
      color:const Color(0xFFEAF2FF),borderRadius:BorderRadius.circular(12)),
      child:Icon(icon,color:Brand.blue)),
    title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700,color:Brand.navy)),
    subtitle:subtitle==null?null:Text(subtitle!,style:const TextStyle(fontSize:12)),
    trailing:trailing??const Icon(Icons.chevron_left_rounded,color:Brand.muted));
}

void feedback(BuildContext context,String message){
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message),
    behavior:SnackBarBehavior.floating));
}
