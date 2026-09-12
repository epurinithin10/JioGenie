@echo off
title Deploy JioGenie to Firebase Hosting
echo ========================================================
echo Deploying JioGenie Frontend to Firebase Hosting...
echo ========================================================
npx --yes firebase-tools deploy
pause
