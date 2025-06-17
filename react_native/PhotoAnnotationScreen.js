import React, { useState, useRef } from 'react';
import { View, Button, StyleSheet, TextInput, TouchableOpacity, Text, PanResponder } from 'react-native';
import Svg, { Line, Circle, Text as SvgText } from 'react-native-svg';
import AnnotatedImage from './AnnotatedImage';

export default function PhotoAnnotationScreen({ photo, onSave, onClose }) {
  const [annotations, setAnnotations] = useState(photo.annotations || []);
  const [currentTool, setCurrentTool] = useState('arrow');
  const [temp, setTemp] = useState(null);
  const [labelText, setLabelText] = useState('');

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => currentTool !== 'label',
      onPanResponderGrant: (e) => {
        const { locationX: x, locationY: y } = e.nativeEvent;
        setTemp({ startX: x, startY: y, endX: x, endY: y });
      },
      onPanResponderMove: (e) => {
        const { locationX: x, locationY: y } = e.nativeEvent;
        setTemp((prev) => (prev ? { ...prev, endX: x, endY: y } : null));
      },
      onPanResponderRelease: () => {
        if (!temp) return;
        if (currentTool === 'arrow') {
          setAnnotations([...annotations, { type: 'arrow', ...temp }]);
        } else if (currentTool === 'circle') {
          const dx = temp.endX - temp.startX;
          const dy = temp.endY - temp.startY;
          const r = Math.sqrt(dx * dx + dy * dy);
          setAnnotations([...annotations, { type: 'circle', x: temp.startX, y: temp.startY, r }]);
        }
        setTemp(null);
      },
    })
  ).current;

  const handleLabelPlace = (e) => {
    if (currentTool !== 'label' || !labelText) return;
    const { locationX: x, locationY: y } = e.nativeEvent;
    setAnnotations([...annotations, { type: 'label', x, y, text: labelText }]);
  };

  const renderTemp = () => {
    if (!temp) return null;
    if (currentTool === 'arrow') {
      return <Line x1={temp.startX} y1={temp.startY} x2={temp.endX} y2={temp.endY} stroke="red" strokeWidth="2" />;
    }
    if (currentTool === 'circle') {
      const dx = temp.endX - temp.startX;
      const dy = temp.endY - temp.startY;
      const r = Math.sqrt(dx * dx + dy * dy);
      return <Circle cx={temp.startX} cy={temp.startY} r={r} stroke="red" strokeWidth="2" fill="none" />;
    }
    return null;
  };

  return (
    <View style={styles.container}>
      <View style={styles.toolbar}>
        {['arrow', 'circle', 'label'].map((t) => (
          <TouchableOpacity key={t} onPress={() => setCurrentTool(t)}>
            <Text style={currentTool === t ? styles.activeTool : styles.tool}>{t}</Text>
          </TouchableOpacity>
        ))}
        {currentTool === 'label' && (
          <TextInput
            style={styles.labelInput}
            placeholder="Label"
            value={labelText}
            onChangeText={setLabelText}
          />
        )}
        <Button title="Undo" onPress={() => setAnnotations(annotations.slice(0, -1))} />
        <Button title="Save" onPress={() => onSave(annotations)} />
        <Button title="Close" onPress={onClose} />
      </View>
      <View style={styles.canvas} {...panResponder.panHandlers} onStartShouldSetResponder={() => currentTool === 'label'} onResponderRelease={handleLabelPlace}>
        <AnnotatedImage photo={{ ...photo, annotations }} style={{ flex: 1 }} />
        <Svg style={StyleSheet.absoluteFill}>{renderTemp()}</Svg>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  canvas: { flex: 1 },
  toolbar: { flexDirection: 'row', alignItems: 'center', padding: 8, flexWrap: 'wrap' },
  tool: { marginHorizontal: 4, color: '#444' },
  activeTool: { marginHorizontal: 4, color: 'red', fontWeight: 'bold' },
  labelInput: { borderBottomWidth: 1, minWidth: 80, marginHorizontal: 4 },
});
