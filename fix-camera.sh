#!/bin/bash
echo "Parando serviço..."
systemctl --user stop virtual-cam-crop.service

echo "Solicitando permissão de administrador para reconfigurar o módulo da câmera..."
# O pkexec vai abrir uma janela gráfica nativa do Ubuntu pedindo a senha
pkexec bash -c '
    # Remove o módulo atual
    modprobe -r v4l2loopback 2>/dev/null
    
    # Cria a nova configuração com exclusive_caps=0
    echo "options v4l2loopback video_nr=2 card_label=\"Virtual Camera\" exclusive_caps=1" > /etc/modprobe.d/virtualcam.conf
    
    # Carrega o módulo novamente com as novas configurações
    modprobe v4l2loopback
'

echo "Iniciando serviço novamente..."
systemctl --user start virtual-cam-crop.service

echo "Concluído! A câmera foi reconfigurada."
