#!/bin/bash

# ==============================================================================
# Auto Virtual Camera (Crop) - Ubuntu 24.04
# Monitora a câmera virtual e ativa a captura da câmera real apenas quando
# a câmera virtual estiver sendo acessada. Em estado ocioso, mantém um
# frame preto de baixíssimo consumo para que navegadores detectem a câmera.
# ==============================================================================

REAL_CAM="/dev/video0"
VIRTUAL_CAM="/dev/video2"
CROP_FILTER="crop=900:700:300:0"

FFMPEG_CMD="ffmpeg"
FUSER_CMD="fuser"

if ! command -v $FFMPEG_CMD &> /dev/null; then
    echo "Erro: ffmpeg não encontrado. Instale com: sudo apt install ffmpeg"
    exit 1
fi

if ! command -v $FUSER_CMD &> /dev/null; then
    echo "Erro: fuser não encontrado. Instale com: sudo apt install psmisc"
    exit 1
fi

FFMPEG_PID=""
CURRENT_STATE="none"

# ==============================================================================
# Oculta a câmera real dos navegadores (e do usuário) alterando as permissões.
# Como o script agora roda como root (via systemd), ele continua tendo acesso.
# ==============================================================================
chmod 0600 "$REAL_CAM" 2>/dev/null
setfacl -b "$REAL_CAM" 2>/dev/null || true
# Se houver nó de metadados associado (geralmente video1), oculta também
chmod 0600 "/dev/video1" 2>/dev/null
setfacl -b "/dev/video1" 2>/dev/null || true

start_dummy_producer() {
    if [ "$CURRENT_STATE" == "dummy" ]; then
        if kill -0 "$FFMPEG_PID" 2>/dev/null; then
            return
        fi
    fi

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Estado Ocioso: Mantendo sinal de standby (tela preta, baixíssimo consumo)..."
    
    if [ -n "$FFMPEG_PID" ]; then
        kill "$FFMPEG_PID" 2>/dev/null
        wait "$FFMPEG_PID" 2>/dev/null
    fi

    # Envia um frame preto a 1 fps para manter o dispositivo ativo para o Chrome/Meet
    $FFMPEG_CMD -loglevel error -re -f lavfi -i color=c=black:s=900x700:r=1 -pix_fmt yuv420p -f v4l2 "$VIRTUAL_CAM" > /dev/null 2>&1 &
    FFMPEG_PID=$!
    CURRENT_STATE="dummy"
}

start_real_producer() {
    if [ "$CURRENT_STATE" == "real" ]; then
        if kill -0 "$FFMPEG_PID" 2>/dev/null; then
            return
        fi
    fi

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Navegador detectado! Iniciando captura e crop da câmera real..."
    
    if [ -n "$FFMPEG_PID" ]; then
        kill "$FFMPEG_PID" 2>/dev/null
        wait "$FFMPEG_PID" 2>/dev/null
    fi

    # Força 30fps em formato MJPEG para evitar lag/lentidão, já que o YUYV nativo roda a 10fps
    $FFMPEG_CMD -loglevel error -fflags nobuffer -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 30 -i "$REAL_CAM" -vf "$CROP_FILTER" -pix_fmt yuv420p -f v4l2 "$VIRTUAL_CAM" > /dev/null 2>&1 &
    FFMPEG_PID=$!
    
    # Pequeno delay para garantir que se o ffmpeg falhar imediatamente (ex: câmera real em uso), a gente perceba.
    sleep 0.5
    if ! kill -0 "$FFMPEG_PID" 2>/dev/null; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Erro: Câmera real ocupada ou falha ao iniciar. Retornando ao standby."
        CURRENT_STATE="none"
        start_dummy_producer
    else
        CURRENT_STATE="real"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Câmera real ativada (PID: $FFMPEG_PID)."
    fi
}

cleanup() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Encerrando monitoramento..."
    if [ -n "$FFMPEG_PID" ]; then
        kill "$FFMPEG_PID" 2>/dev/null
    fi
    exit 0
}

trap cleanup EXIT INT TERM

echo "================================================================="
echo " Monitor de Câmera Virtual Inteligente (com Standby e yuv420p)"
echo " Dispositivo Real: $REAL_CAM"
echo " Dispositivo Virtual: $VIRTUAL_CAM"
echo " Filtro de Crop: $CROP_FILTER"
echo "================================================================="

start_dummy_producer

while true; do
    # Garante que a câmera física continue oculta mesmo após o notebook suspender/voltar (o que pode resetar o USB)
    chmod 0600 "$REAL_CAM" 2>/dev/null
    setfacl -b "$REAL_CAM" 2>/dev/null || true
    chmod 0600 "/dev/video1" 2>/dev/null
    setfacl -b "/dev/video1" 2>/dev/null || true

    PIDS=$($FUSER_CMD "$VIRTUAL_CAM" 2>/dev/null)
    
    IN_USE=false
    
    if [ -n "$PIDS" ]; then
        for PID in $PIDS; do
            PID_CLEAN=$(echo "$PID" | tr -dc '0-9')
            if [ -n "$PID_CLEAN" ] && [ "$PID_CLEAN" != "$FFMPEG_PID" ] && [ "$PID_CLEAN" != "$$" ]; then
                IN_USE=true
                break
            fi
        done
    fi

    if [ "$IN_USE" = true ]; then
        if [ "$CURRENT_STATE" != "real" ]; then
            start_real_producer
        fi
    else
        if [ "$CURRENT_STATE" != "dummy" ]; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Reunião encerrada ou câmera ociosa."
            start_dummy_producer
        fi
    fi

    sleep 2
done
