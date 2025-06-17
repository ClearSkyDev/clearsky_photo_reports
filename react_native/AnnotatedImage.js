import React from 'react';
import { View, Image } from 'react-native';
import Svg, { Line, Circle, Text as SvgText } from 'react-native-svg';

export default function AnnotatedImage({ photo, style }) {
  const annotations = photo.annotations || [];

  const renderAnnotations = () =>
    annotations.map((a, idx) => {
      if (a.type === 'arrow') {
        const head = 10;
        const angle = Math.atan2(a.endY - a.startY, a.endX - a.startX);
        const x1 = a.endX - head * Math.cos(angle - Math.PI / 6);
        const y1 = a.endY - head * Math.sin(angle - Math.PI / 6);
        const x2 = a.endX - head * Math.cos(angle + Math.PI / 6);
        const y2 = a.endY - head * Math.sin(angle + Math.PI / 6);
        const mx = (a.startX + a.endX) / 2;
        const my = (a.startY + a.endY) / 2;
        return (
          <React.Fragment key={idx}>
            <Line x1={a.startX} y1={a.startY} x2={a.endX} y2={a.endY} stroke="red" strokeWidth="2" />
            <Line x1={a.endX} y1={a.endY} x2={x1} y2={y1} stroke="red" strokeWidth="2" />
            <Line x1={a.endX} y1={a.endY} x2={x2} y2={y2} stroke="red" strokeWidth="2" />
            {a.measurement ? (
              <SvgText x={mx} y={my - 4} fill="red" fontSize="16" textAnchor="middle">
                {a.measurement}
              </SvgText>
            ) : null}
          </React.Fragment>
        );
      } else if (a.type === 'circle') {
        return (
          <React.Fragment key={idx}>
            <Circle cx={a.x} cy={a.y} r={a.r} stroke="red" strokeWidth="2" fill="none" />
            {a.measurement ? (
              <SvgText x={a.x} y={a.y + a.r + 16} fill="red" fontSize="16" textAnchor="middle">
                {a.measurement}
              </SvgText>
            ) : null}
          </React.Fragment>
        );
      } else if (a.type === 'label') {
        return (
          <SvgText key={idx} x={a.x} y={a.y} fill="red" fontSize="16">
            {a.text}
          </SvgText>
        );
      } else if (a.type === 'line') {
        const mx = (a.startX + a.endX) / 2;
        const my = (a.startY + a.endY) / 2;
        return (
          <React.Fragment key={idx}>
            <Line x1={a.startX} y1={a.startY} x2={a.endX} y2={a.endY} stroke="red" strokeWidth="2" />
            {a.measurement ? (
              <SvgText x={mx} y={my - 4} fill="red" fontSize="16" textAnchor="middle">
                {a.measurement}
              </SvgText>
            ) : null}
          </React.Fragment>
        );
      }
      return null;
    });

  return (
    <View style={[{ position: 'relative' }, style]}>
      <Image source={{ uri: photo.imageUri }} style={{ width: '100%', height: '100%' }} resizeMode="contain" />
      <Svg style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0 }}>
        {renderAnnotations()}
      </Svg>
    </View>
  );
}
