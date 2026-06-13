#!/bin/bash
echo "Parando serviço antigo de usuário (se existir)..."
systemctl --user stop virtual-cam-crop.service 2>/dev/null
systemctl --user disable virtual-cam-crop.service 2>/dev/null

echo "Solicitando permissão de administrador para configurar o módulo e o serviço do sistema..."
pkexec bash -c '
    # Configura o módulo v4l2loopback
    modprobe -r v4l2loopback 2>/dev/null
    echo "options v4l2loopback video_nr=2 card_label=\"Virtual Camera\" exclusive_caps=1" > /etc/modprobe.d/virtualcam.conf
    echo "v4l2loopback" > /etc/modules-load.d/v4l2loopback.conf
    modprobe v4l2loopback

    # Instala o script como um serviço do sistema (roda como root)
    cat << "SERVICE_EOF" > /etc/systemd/system/virtual-cam-crop.service
[Unit]
Description=Auto Virtual Camera Crop Monitor
After=network.target

[Service]
Type=simple
ExecStart=/home/a-p/Scripts/virtual-cam-cropped/virtual-cropped-cam.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload
    systemctl enable --now virtual-cam-crop.service
'

echo "Concluído! A câmera foi reconfigurada como um serviço de sistema."
