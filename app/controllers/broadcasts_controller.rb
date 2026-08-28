class BroadcastsController < ApplicationController
  layout false
  skip_before_action :authenticate_user!, only: :index

  def index
    @broadcasts = [
      {
        name: "TV TESTE",
        media: "Slides TV 03.12.24.ts",
        status: "Offline",
        active: false,
        app: "Oficial",
        tv: "Normal",
        ip: "-",
        energy: "Wake-on-LAN para ligar",
        official_web: "Sem alternancia web no app oficial",
        flow_title: "FFmpeg / HLS",
        flow_url: "http://192.168.1.98:8080/hls/stream.m3u8",
        preview: :unavailable
      },
      {
        name: "TV SOFTEX ADM",
        media: "download.mp4",
        status: "Online",
        active: true,
        app: "Oficial",
        tv: "Android",
        ip: "192.168.1.151",
        energy: "ADB via IP:5555 para ligar e desligar",
        official_web: "Abre ao terminar o video, exibe por 20s, transicao slide, video direto do servidor",
        flow_title: "Video direto",
        flow_url: "http://192.168.1.98:8080/broadcasts/2/mobile_prepared_video",
        preview: :phone
      },
      {
        name: "TV CORREDOR",
        media: "Design_sem nome (21).mp4",
        status: "Offline",
        active: false,
        app: "Oficial",
        tv: "Android",
        ip: "192.168.1.180",
        energy: "ADB via IP:5555 para ligar e desligar",
        official_web: "Sem alternancia web no app oficial",
        flow_title: "FFmpeg / HLS",
        flow_url: "http://192.168.1.98:8080/hls/stream.m3u8",
        preview: :blank_phone
      }
    ]
  end
end
